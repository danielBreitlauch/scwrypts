#
# configuration options for scwrypts
#

SCWRYPTS_GROUPS=()

SCWRYPTS_CONFIG_PATH="$HOME/.config/scwrypts"
SCWRYPTS_DATA_PATH="$HOME/.local/share/scwrypts"

[ -d /tmp ] \
	&& SCWRYPTS_TEMP_PATH=/tmp/scwrypts \
	|| SCWRYPTS_TEMP_PATH="$HOME/.cache/scwrypts" \
	;

SCWRYPTS_SHORTCUT=' '         # CTRL + SPACE
SCWRYPTS_ENV_SHORTCUT=''     # CTRL + /
SCWRYPTS_BUILDER_SHORTCUT='' # CTRL + Y

SCWRYPTS_ENV_PATH="$SCWRYPTS_CONFIG_PATH/environments"
SCWRYPTS_LOG_PATH="$SCWRYPTS_DATA_PATH/logs"
SCWRYPTS_OUTPUT_PATH="$SCWRYPTS_DATA_PATH/output"


#####################################################################

# true / false; include help information during environment edit
SCWRYPTS_ENVIRONMENT__SHOW_ENV_HELP=true

# basic / quiet; swaps the default environment editor mode
SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE=basic

#####################################################################

# disabled = 0; enabled = 1

SCWRYPTS_PLUGIN_ENABLED__kubectl=1
