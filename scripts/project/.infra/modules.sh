#!/usr/bin/env bash

helper_modules_is_excluded() {
  local module_name="$1"
  shift
  local excluded=""
  for excluded in "$@"; do
    if [ "$module_name" = "$excluded" ]; then
      return 0
    fi
  done
  return 1
}

helper_modules_generate_conf() {
  local modules_dir="$1"
  local conf_path="$2"
  shift 2
  local tmp_conf
  local module_name
  tmp_conf="$(mktemp)"

  (
    cd "${modules_dir}"
    find . -maxdepth 1 -mindepth 1 -type f -name '*.sh' \
      | sed -E 's#^\./##' \
      | sort
  ) | while IFS= read -r module_name; do
    if helper_modules_is_excluded "$module_name" "$@"; then
      continue
    fi
    printf '%s\n' "$module_name"
  done >"${tmp_conf}"

  mv "${tmp_conf}" "${conf_path}"
}

helper_modules_conf_has_nested_entries() {
  local conf_path="$1"
  [ -f "${conf_path}" ] || return 1
  rg -q '^[^#[:space:]].*/' "${conf_path}"
}

helper_modules_conf_matches_directory() {
  local modules_dir="$1"
  local conf_path="$2"
  shift 2
  local tmp_dir_list
  local tmp_conf_list
  tmp_dir_list="$(mktemp)"
  tmp_conf_list="$(mktemp)"

  (
    cd "${modules_dir}"
    find . -maxdepth 1 -mindepth 1 -type f -name '*.sh' \
      | sed -E 's#^\./##' \
      | sort
  ) | while IFS= read -r module_name; do
    if helper_modules_is_excluded "$module_name" "$@"; then
      continue
    fi
    printf '%s\n' "$module_name"
  done >"${tmp_dir_list}"

  awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    { print }
  ' "${conf_path}" | sort >"${tmp_conf_list}"

  if cmp -s "${tmp_dir_list}" "${tmp_conf_list}"; then
    rm -f "${tmp_dir_list}" "${tmp_conf_list}"
    return 0
  fi

  rm -f "${tmp_dir_list}" "${tmp_conf_list}"
  return 1
}

helper_modules_source_from_conf() {
  local modules_dir="$1"
  local conf_path="$2"
  local module_rel_path=""
  local module_abs_path=""

  while IFS= read -r module_rel_path || [ -n "${module_rel_path}" ]; do
    case "${module_rel_path}" in
    "" | \#*)
      continue
      ;;
    esac
    module_abs_path="${modules_dir}/${module_rel_path}"
    if [ ! -f "${module_abs_path}" ]; then
      echo "Missing module listed in ${conf_path}: ${module_rel_path}" >&2
      return 1
    fi
    source "${module_abs_path}"
  done <"${conf_path}"
}

helper_modules_bootstrap() {
  local modules_dir="$1"
  local conf_path="$2"
  shift 2

  if [ ! -f "${conf_path}" ]; then
    helper_modules_generate_conf "${modules_dir}" "${conf_path}" "$@"
  fi
  if helper_modules_conf_has_nested_entries "${conf_path}"; then
    helper_modules_generate_conf "${modules_dir}" "${conf_path}" "$@"
  fi
  if ! helper_modules_conf_matches_directory "${modules_dir}" "${conf_path}" "$@"; then
    helper_modules_generate_conf "${modules_dir}" "${conf_path}" "$@"
  fi

  helper_modules_source_from_conf "${modules_dir}" "${conf_path}"
}
