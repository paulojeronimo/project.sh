#!/usr/bin/env bash

HELP_MODULES_DIR="${BASE_DIR}/scripts/project/help"
HELP_MODULES_CONF="${HELP_MODULES_DIR}/modules.conf"

helper_help_module_id_from_relpath() {
  local module_rel="$1"
  local module_name="${module_rel%.sh}"
  echo "${module_name//[^a-zA-Z0-9_]/_}"
}

helper_help_usage_fn_for_module() {
  local module_rel="$1"
  local module_id
  module_id="$(helper_help_module_id_from_relpath "${module_rel}")"
  echo "help_usage_${module_id}_commands"
}

helper_help_validate_for_modules() {
  local project_modules_conf="$1"
  local rc=0
  local module_rel=""

  while IFS= read -r module_rel || [ -n "${module_rel}" ]; do
    case "${module_rel}" in
    "" | \#*)
      continue
      ;;
    esac

    local help_path="${HELP_MODULES_DIR}/${module_rel}"
    if [ ! -f "${help_path}" ]; then
      echo "Missing help module for ${module_rel}: expected ${help_path}" >&2
      rc=1
      continue
    fi

    local usage_fn
    usage_fn="$(helper_help_usage_fn_for_module "${module_rel}")"
    if ! declare -F "${usage_fn}" >/dev/null 2>&1; then
      echo "Missing help usage function ${usage_fn} for ${module_rel}." >&2
      rc=1
    fi
  done <"${project_modules_conf}"

  return "${rc}"
}

helper_help_bootstrap() {
  if [ ! -d "${HELP_MODULES_DIR}" ]; then
    return 0
  fi

  helper_modules_bootstrap "${HELP_MODULES_DIR}" "${HELP_MODULES_CONF}"
}

usage() {
  echo "Usage: ./project.sh <command> [args]"
  echo
  echo "Available commands:"

  local module_rel=""
  while IFS= read -r module_rel || [ -n "${module_rel}" ]; do
    case "${module_rel}" in
    "" | \#*)
      continue
      ;;
    esac
    local usage_fn
    usage_fn="$(helper_help_usage_fn_for_module "${module_rel}")"
    if declare -F "${usage_fn}" >/dev/null 2>&1; then
      "${usage_fn}"
    fi
  done <"${PROJECT_MODULES_CONF}"
}
