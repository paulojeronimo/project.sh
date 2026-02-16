#!/usr/bin/env bash

HELP_MODULES_DIR="${BASE_DIR}/scripts/project/help"
HELP_MODULES_CONF="${HELP_MODULES_DIR}/modules.conf"

if [ -d "${HELP_MODULES_DIR}" ]; then
  helper_modules_bootstrap "${HELP_MODULES_DIR}" "${HELP_MODULES_CONF}"
fi

usage() {
  echo "Usage: ./project.sh <command> [args]"
  echo
  echo "Core commands:"
  if declare -F help_usage_info_commands >/dev/null 2>&1; then
    help_usage_info_commands
  fi
  echo
  echo "No other command modules are bundled by default in project.sh core."
  echo "Add modules under scripts/project/*.sh in your repository to extend commands."
}
