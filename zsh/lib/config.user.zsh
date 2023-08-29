#
# configuration options for scwrypts
#

SCWRYPTS_GROUPS=()

SCWRYPTS_CONFIG_PATH="$HOME/.config/scwrypts"
SCWRYPTS_DATA_PATH="$HOME/.local/share/scwrypts"

SCWRYPTS_SHORTCUT=' '     # CTRL + SPACE
SCWRYPTS_ENV_SHORTCUT='' # CTRL + /

SCWRYPTS_ENV_PATH="$SCWRYPTS_CONFIG_PATH/environments"
SCWRYPTS_LOG_PATH="$SCWRYPTS_DATA_PATH/logs"
SCWRYPTS_OUTPUT_PATH="$SCWRYPTS_DATA_PATH/output"


# disabled = 0; enabled = 1

SCWRYPTS_PLUGIN_ENABLED__kubectl=1
