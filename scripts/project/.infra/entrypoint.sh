#!/usr/bin/env bash

action_default() {
  usage
  return 0
}

action_private_sync() {
  cli_private_sync "$@"
}

action_up() {
  cli_profile up "$@"
}

action_restart() {
  cli_profile restart "$@"
}

action_web_static() {
  cli_web_static "$@"
}

action_sync_to() {
  cli_remote_script ./scripts/sync-to.sh "$@"
}

action_ssh_to() {
  cli_remote_script ./scripts/ssh-to.sh "$@"
}

action_down() {
  cli_profile down "$@"
}

action_logs() {
  cli_profile logs "$@"
}

action_logs_path() {
  show_help_if_requested "${2:-}"
  cli_logs_path
}

action_clean() {
  cli_clean "$@"
}

action_docker_reset() {
  # Backward-compatible alias; prefer: ./project.sh docker reset
  show_help_if_requested "${2:-}"
  helper_docker_reset_project
}

action_docker() {
  cli_docker "$@"
}

action_bundle() {
  show_help_if_requested "${2:-}"
  helper_bundle_parent_tree
}

action_issues_report() {
  show_help_if_requested "${2:-}"
  helper_issues_report
}

action_serve() {
  show_help_if_requested "${2:-}"
  shift
  helper_serve_action "${1:-}"
}

action_github() {
  cli_github "$@"
}

action_todo() {
  cli_todo "$@"
}

helper_action_requires_functions() {
  local fn_name=""
  for fn_name in "$@"; do
    if ! declare -F "$fn_name" >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

helper_action_is_available() {
  local action_fn="${1:-}"
  case "$action_fn" in
  action_default)
    return 0
    ;;
  action_build_sample_pdf | action_test_pdf_worker)
    helper_action_requires_functions "$action_fn"
    ;;
  action_private_sync)
    helper_action_requires_functions cli_private_sync
    ;;
  action_up | action_restart | action_web_static | action_down | action_logs)
    helper_action_requires_functions cli_profile
    ;;
  action_sync_to | action_ssh_to)
    helper_action_requires_functions cli_remote_script
    ;;
  action_logs_path)
    helper_action_requires_functions cli_logs_path
    ;;
  action_clean)
    helper_action_requires_functions cli_clean
    ;;
  action_docker_reset)
    helper_action_requires_functions helper_docker_reset_project
    ;;
  action_docker)
    helper_action_requires_functions cli_docker
    ;;
  action_bundle)
    helper_action_requires_functions helper_bundle_parent_tree
    ;;
  action_issues_report)
    helper_action_requires_functions helper_issues_report
    ;;
  action_serve)
    helper_action_requires_functions helper_serve_action
    ;;
  action_github)
    helper_action_requires_functions cli_github
    ;;
  action_todo)
    helper_action_requires_functions cli_todo
    ;;
  action_info)
    helper_action_requires_functions action_info
    ;;
  action_self_update)
    helper_action_requires_functions action_self_update
    ;;
  *)
    return 1
    ;;
  esac
}

resolve_action_function() {
  local action="${1:-}"
  if [ -z "$action" ]; then
    echo "action_default"
    return 0
  fi

  local normalized="${action//-/_}"
  local fn="action_${normalized}"
  if declare -F "$fn" >/dev/null 2>&1 && helper_action_is_available "$fn"; then
    echo "$fn"
    return 0
  fi
  echo ""
  return 1
}

main() {
  local action="${1:-}"
  local action_fn=""
  action_fn="$(resolve_action_function "$action" || true)"
  if [ -z "$action_fn" ]; then
    echo "Unknown command: ${action}"
    usage
    return 1
  fi
  "$action_fn" "$@"
}
