#!/usr/bin/env bash

project_sh_info_file() {
  echo "${BASE_DIR}/scripts/project.sh.info"
}

helper_project_sh_require_info_file() {
  local info_file
  info_file="$(project_sh_info_file)"
  if [ ! -f "${info_file}" ]; then
    echo "Missing ${info_file}." >&2
    return 1
  fi
}

action_info() {
  helper_project_sh_require_info_file || return 1
  cat "$(project_sh_info_file)"
}

action_self_update() {
  helper_project_sh_require_info_file || return 1

  # shellcheck source=/dev/null
  source "$(project_sh_info_file)"
  local install_url="${PROJECT_SH_ORIGIN_INSTALL:-${PROJECT_SH_ORIGIN:-}}"
  if [ -z "${install_url}" ]; then
    echo "PROJECT_SH_ORIGIN_INSTALL is not set in $(project_sh_info_file)." >&2
    return 1
  fi

  project_core_run_without_tee sh -c "curl -sSL \"${install_url}\" | sh"
}
