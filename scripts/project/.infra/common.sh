# shellcheck shell=bash

is_help_flag() {
  case "${1:-}" in
  --help | -h)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

show_help_if_requested() {
  local maybe_help_fn="${1:-}"
  local maybe_arg="${2:-}"
  local help_fn=""
  local arg=""

  if [ -n "$maybe_arg" ]; then
    help_fn="$maybe_help_fn"
    arg="$maybe_arg"
  elif is_help_flag "$maybe_help_fn"; then
    help_fn="$(helper_infer_help_from_action_caller "${FUNCNAME[1]:-}" "show_help_if_requested")"
    arg="$maybe_help_fn"
  else
    help_fn="$maybe_help_fn"
    arg="$maybe_arg"
  fi

  if [ -z "$help_fn" ]; then
    help_fn="$(helper_infer_help_from_action_caller "${FUNCNAME[1]:-}" "show_help_if_requested")"
  fi

  if is_help_flag "$arg"; then
    "$help_fn"
    exit 0
  fi
}

helper_script_with_optional_env() {
  local script_path="$1"
  local env_value="${2:-}"
  if [ -n "$env_value" ]; then
    ENV="$env_value" "$script_path"
  else
    "$script_path"
  fi
}

helper_infer_help_from_action_caller() {
  local caller_fn="${1:-}"
  local cli_name="${2:-unknown_cli}"
  local caller_suffix="$caller_fn"
  if [[ "$caller_fn" == action_* ]]; then
    caller_suffix="${caller_fn#action_}"
  elif [[ "$caller_fn" == cli_* ]]; then
    caller_suffix="${caller_fn#cli_}"
  fi
  local help_fn="help_${caller_suffix}"
  if [ -z "$caller_fn" ] || ! declare -F "$help_fn" >/dev/null 2>&1; then
    echo "Internal error: could not infer help function for ${cli_name} (caller=${caller_fn})." >&2
    exit 1
  fi
  echo "$help_fn"
}
