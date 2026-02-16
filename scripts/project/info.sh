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

  local modules_conf="${BASE_DIR}/scripts/project/modules.conf"
  local backup_modules_conf=""
  local should_restore_modules_conf=0
  local origin_modules_url=""
  local install_base="${install_url}"
  install_base="${install_base%%\?*}"
  install_base="${install_base%%\#*}"

  case "${install_base}" in
  */install)
    origin_modules_url="${install_base%/install}/scripts/project/modules.conf"
    ;;
  */install.sh)
    origin_modules_url="${install_base%/install.sh}/scripts/project/modules.conf"
    ;;
  esac

  if [ -f "${modules_conf}" ]; then
    local origin_tmp=""
    origin_tmp="$(mktemp)"
    if [ -n "${origin_modules_url}" ] && curl -fsSL "${origin_modules_url}" -o "${origin_tmp}" 2>/dev/null; then
      if ! cmp -s "${modules_conf}" "${origin_tmp}"; then
        should_restore_modules_conf=1
      fi
    else
      # Conservative fallback: preserve local modules.conf when origin baseline
      # cannot be resolved.
      should_restore_modules_conf=1
    fi
    rm -f "${origin_tmp}"
  fi

  if [ "${should_restore_modules_conf}" -eq 1 ]; then
    backup_modules_conf="$(mktemp)"
    cp "${modules_conf}" "${backup_modules_conf}"
  fi

  if ! project_core_run_without_tee curl -sSL "${install_url}" | sh; then
    rm -f "${backup_modules_conf}"
    return 1
  fi

  if [ "${should_restore_modules_conf}" -eq 1 ] && [ -n "${backup_modules_conf}" ]; then
    cp "${backup_modules_conf}" "${modules_conf}"
    rm -f "${backup_modules_conf}"
    echo "Restored local scripts/project/modules.conf after self-update."
  fi
}
