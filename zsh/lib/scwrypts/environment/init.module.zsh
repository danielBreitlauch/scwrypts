#####################################################################

use scwrypts/environment/common

use scwrypts/environment/update
use scwrypts/environment/template

#####################################################################

SCWRYPTS_ENVIRONMENT__INIT_ENVIRONMENTS() {
	[ $CI ] && return 0

	mkdir -p "$SCWRYPTS_ENV_PATH"
	[[ $(_SCWRYPTS_ENVIRONMENT__FIND_ENV_FILES | wc -l) -gt 0 ]] && return 0

	[[ $(_SCWRYPTS_ENVIRONMENT__FIND_LEGACY_ENV_FILES | wc -l) -gt 0 ]] && {
		_SCWRYPTS_ENVIRONMENT__CONVERT
		return $?
	}

	STATUS "initializing environments for scwrypts"

	local BASIC_ENV
	for BASIC_ENV in local dev prod
	do
		SCWRYPTS_ENVIRONMENT__UPDATE_USER_CONFIG --environment-name "$BASIC_ENV"
	done
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__FIND_LEGACY_ENV_FILES() {
	find "$SCWRYPTS_ENV_PATH/" -mindepth 2 -maxdepth 2 -type f 2>/dev/null
}

_SCWRYPTS_ENVIRONMENT__FIND_LEGACY_ENV_NAMES() {
	_SCWRYPTS_ENVIRONMENT__FIND_LEGACY_ENV_FILES \
		| sed 's|.*/||' \
		| sort --unique \
		;
}

#####################################################################

_SCWRYPTS_ENVIRONMENT__CONVERT() {
	local GROUP GROUP_ROOT
	local GROUP_TEMPLATE_FILENAME LEGACY_TEMPLATE_FILENAME

	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		GROUP_ROOT="$(eval echo '$SCWRYPTS_ROOT__'$GROUP)"
		GROUP_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.yaml"
		LEGACY_TEMPLATE_FILENAME="$GROUP_ROOT/.config/env.template"

		[ ! -f "$GROUP_TEMPLATE_FILENAME" ] && [ -f "$LEGACY_TEMPLATE_FILENAME" ] && {
			_SCWRYPTS_ENVIRONMENT__CONVERT__V4_TO_V5__TEMPLATE_FILE
		}

		#[ -f "$GROUP_TEMPLATE_FILENAME" ] && SUCCESS "environment template '$GROUP' OK"
	done

	local ENVIRONMENT_NAME
	local GROUP_CONFIG_FILENAME LEGACY_CONFIG_FILENAME
	for ENVIRONMENT_NAME in $(_SCWRYPTS_ENVIRONMENT__FIND_LEGACY_ENV_NAMES)
	do
		local MIGRATE_GROUP=false
		STATUS "checking '$ENVIRONMENT_NAME' configuration files"
		for GROUP in ${SCWRYPTS_GROUPS[@]}
		do
			GROUP_CONFIG_FILENAME="$(SCWRYPTS_ENVIRONMENT__GET_ENV_FILE_NAME "$ENVIRONMENT_NAME" "$GROUP")"
			LEGACY_CONFIG_FILENAME="$SCWRYPTS_ENV_PATH/$GROUP/$ENVIRONMENT_NAME"

			[ ! -f "$GROUP_CONFIG_FILENAME" ] && [ -f "$LEGACY_CONFIG_FILENAME" ] && {
				MIGRATE_GROUP=true
			}
		done

		[[ $MIGRATE_GROUP =~ true ]] && {
			_SCWRYPTS_ENVIRONMENT__CONVERT__V4_TO_V5__CONFIG_FILE \
				&& SUCCESS "successfully migrated '$ENVIRONMENT_NAME'"
		}
	done
}

_SCWRYPTS_ENVIRONMENT__CONVERT__V4_TO_V5__TEMPLATE_FILE() {
	_SCWRYPTS_ENVIRONMENT__CONVERT__deprecation_warning

	STATUS "detected legacy template for '$GROUP'; attempting v5 conversion"

	"$SCWRYPTS_ROOT__scwrypts/.config/create-new-env" "$GROUP_ROOT/.config" "$GROUP" &>/dev/null

	EDIT "$GROUP_TEMPLATE_FILENAME"

	REMINDER "the file '$GROUP_TEMPLATE_FILENAME' should be committed to the appropriate repository"
}

_SCWRYPTS_ENVIRONMENT__CONVERT__V4_TO_V5__CONFIG_FILE() {
	_SCWRYPTS_ENVIRONMENT__CONVERT__deprecation_warning

	SCWRYPTS_LOG_LEVEL=4 STATUS "detected legacy environment configuration file for '$ENVIRONMENT_NAME'; attempting v5 conversion"

	local LEGACY_CONFIG_FILE
	local LEGACY_CONFIG_VALUES="$(
	cat "$SCWRYPTS_ENV_PATH/"*"/$ENVIRONMENT_NAME" \
		| sed '/^#/d; /^$/d; /=$/d; /# from/d' \
		| sed -z 's/\n\s\+/ /g' \
		| sed -z 's/\n)/)/g' \
		| sed 's/( /\n(/' \
		| sed '/^(/{s/ /,/g}; s/^(\(.*\))$/[\1]/' \
		| sed '/^\[/{s|\([^][,]\+\)|"\1"|g}' \
		| sed "s/^\\[.*\\]$/'&'/" \
		| sed -z "s/\\n'\[/'[/g" \
		| sed 's/^export \([^=]\+\)=/\1: /' \
		| YQ --unwrapScalar=false '..style="double"' \
	)"

	local ENV_VAR NEW_TEMPLATE_KEY NEW_TEMPLATE="$(SCWRYPTS_ENVIRONMENT__GET_FULL_TEMPLATE --reset-cache)"
	for ENV_VAR in $(echo "$LEGACY_CONFIG_VALUES" | YQ -r 'keys | .[]')
	do
		NEW_TEMPLATE_KEY=$(SCWRYPTS_ENVIRONMENT__GET_ENVVAR_LOOKUP_MAP | YQ -r ".$ENV_VAR")
		NEW_TEMPLATE_VALUE="$(echo "$LEGACY_CONFIG_VALUES" | YQ -r ".$ENV_VAR")"
		echo "$NEW_TEMPLATE_VALUE" | grep -q '^[[].*[]]$' \
			|| NEW_TEMPLATE_VALUE="\"$NEW_TEMPLATE_VALUE\""

		NEW_TEMPLATE="$(
			echo "$NEW_TEMPLATE" | YQ "$NEW_TEMPLATE_KEY = $NEW_TEMPLATE_VALUE"
		)"
	done

	_SCWRYPTS_ENVIRONMENT__UPDATE_USER_CONFIGS "$NEW_TEMPLATE" "$ENVIRONMENT_NAME"
}

export __SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING=false
export __SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING=true
_SCWRYPTS_ENVIRONMENT__CONVERT__deprecation_warning() {
	[[ $__SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING =~ true ]] && return 0

	WARNING "DEPRECATED : the v4 to v5 environment migration is temporary and will be removed in 5.2"
	export __SCWRYPTS_ENVIRONMENT__DEPRECATION_WARNING=true
}
