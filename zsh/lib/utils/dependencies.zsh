__CHECK_DEPENDENCIES() {
	local DEP ERROR=0

	DEPENDENCIES=($(echo $DEPENDENCIES | sed 's/ \+/\n/g' | sort -u))

	for DEP in ${DEPENDENCIES[@]}; do __CHECK_DEPENDENCY $DEP || ((ERROR+=1)); done
	__CHECK_COREUTILS || ((ERROR+=$?))

	return $ERROR
}

__CHECK_DEPENDENCY() {
	local DEPENDENCY="$1"
	[ ! $DEPENDENCY ] && return 1
	command -v $DEPENDENCY >/dev/null 2>&1 || {
		ERROR "'$1' required but not available on PATH $(__CREDITS $1)"
		return 1
	}
}

__CHECK_COREUTILS() {
	local COREUTILS=(awk find grep sed readlink)
	local MISSING_DEPENDENCY_COUNT=0
	local NON_GNU_DEPENDENCY_COUNT=0

	local UTIL
	for UTIL in $(echo $COREUTILS)
	do
		__CHECK_DEPENDENCY $UTIL || { ((MISSING_DEPENDENCY_COUNT+=1)); continue; }

		$UTIL --version 2>&1 | grep -q 'GNU' || {
			WARNING "non-GNU version of $UTIL detected"
			((NON_GNU_DEPENDENCY_COUNT+=1))
		}
	done

	[[ $NON_GNU_DEPENDENCY_COUNT -gt 0 ]] && {
		WARNING 'scripts rely on GNU coreutils; functionality may be limited'
		IS_MACOS && REMINDER 'GNU coreutils can be installed and linked through Homebrew'
	}

	return $MISSING_DEPENDENCY_COUNT
}