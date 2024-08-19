${scwryptsmodule}() {
	# local ACCOUNT REGION                        parsed/configured $AWS_ACCOUNT and $AWS_REGION (use this instead of direct env-var)
	# local AWS=() AWS_PASSTHROUGH=()             used to forward parsed overrides to AWS calls (e.g. 'cloud.aws.cli ${AWS_PASSTHROUGH[@]} your command' or '$AWS your command')
	# local AWS_EVAL_PREFIX AWS_CONTEXT_ARGS=()   should only be used by lib/cloud/aws/cli:AWS
	local PARSED=0

	case $1 in
		--account ) PARSED+=2; ACCOUNT=$2 ;;
		--region  ) PARSED+=2; REGION=$2  ;;
	esac

	return $PARSED
}

${scwryptsmodule}.usage() {
	[[ "$USAGE__usage" =~ ' \[...options...\]' ]] || USAGE__usage+=' [...options...]'

	USAGE__options+="\n
		--account   overrides required AWS_ACCOUNT scwrypts env value
		--region    overrides required AWS_REGION scwrypts env value
	"
}


${scwryptsmodule}.validate() {
	AWS_CONTEXT_ARGS=(--output json)

	[ $ACCOUNT ] || { __CHECK_ENV_VAR AWS_ACCOUNT &>/dev/null && ACCOUNT=$AWS_ACCOUNT; }
	[ $ACCOUNT ] \
		&& AWS_EVAL_PREFIX+="AWS_ACCOUNT=$ACCOUNT " \
		&& AWS_PASSTHROUGH+=(--account $ACCOUNT) \
		|| echo.error "missing either --account or AWS_ACCOUNT" \
		;

	[ $REGION ] || { __CHECK_ENV_VAR AWS_REGION &>/dev/null && REGION=$AWS_REGION; }
	[ $REGION ] \
		&& AWS_EVAL_PREFIX+="AWS_REGION=$REGION AWS_DEFAULT_REGION=$REGION " \
		&& AWS_CONTEXT_ARGS+=(--region $REGION) \
		&& AWS_PASSTHROUGH+=(--region $REGION) \
		|| echo.error "missing either --region  or AWS_REGION" \
		;

	__CHECK_ENV_VAR AWS_PROFILE &>/dev/null
	[ $AWS_PROFILE ] \
		&& AWS_EVAL_PREFIX+="AWS_PROFILE=$AWS_PROFILE " \
		&& AWS_CONTEXT_ARGS+=(--profile $AWS_PROFILE) \
		;

	AWS=(cloud.aws.cli ${AWS_PASSTHROUGH[@]})

	[ ! $CI ] && {
		# non-CI must use PROFILE authentication
		[ $AWS_PROFILE ] || echo.error "missing either --profile or AWS_PROFILE";

		[[ $AWS_PROFILE =~ ^default$ ]] \
			&& echo.warning "it is HIGHLY recommended to NOT use the 'default' profile for aws operations\nconsider using '$USER.$SCWRYPTS_ENV' instead"
	}

	[ $CI ] && {
		# CI can use 'profile' or envvar 'access key' authentication
		[ $AWS_PROFILE ] && return 0  # 'profile' preferred

		[ $AWS_ACCESS_KEY_ID ] && [ $AWS_SECRET_ACCESS_KEY ] \
			&& AWS_EVAL_PREFIX+="AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID " \
			&& AWS_EVAL_PREFIX+="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY " \
			&& return 0

		echo.error "running in CI, but missing both profile and access-key configuration\n(one AWS authentication method *must* be used)"
	}
}