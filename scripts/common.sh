#!/usr/bin/env bash
set -euo pipefail

# Common environment for repo scripts.
# Each script must set BASE_DIR to the repository root before sourcing this file.

if [ -z "${BASE_DIR:-}" ]; then
  echo "Aborting: BASE_DIR is not set (expected repo root)." >&2
  return 1
fi

PROJECT_DIR="$(basename "$BASE_DIR")"

# Runtime data lives next to the repo by default (../<project>.data).
DATA_DIR="${DATA_DIR:-../${PROJECT_DIR}.data}"
DATA_DIR_ABS="$(cd "$BASE_DIR" && mkdir -p "$DATA_DIR" && cd "$DATA_DIR" && pwd)"

# Private files live next to the repo by default (../<project>.private).
PRIVATE_DIR="${PRIVATE_DIR:-../${PROJECT_DIR}.private}"

# Script logs live next to the repo by default (../<project>.logs).
LOG_DIR="${LOG_DIR:-../${PROJECT_DIR}.logs}"
LOG_DIR_ABS="$(cd "$BASE_DIR" && mkdir -p "$LOG_DIR" && cd "$LOG_DIR" && pwd)"

# Helper: fail early with a clear message when DATA_DIR is not writable.
_project_core_assert_data_dir_writable() {
  # We expect runtime data/logs to be writable by the user running scripts.
  if [ ! -d "$DATA_DIR_ABS" ]; then
    echo "Aborting: DATA_DIR_ABS does not exist: $DATA_DIR_ABS" >&2
    return 1
  fi
  if [ ! -w "$DATA_DIR_ABS" ]; then
    echo "Aborting: DATA_DIR is not writable by the current user." >&2
    echo "BASE_DIR=$BASE_DIR" >&2
    echo "DATA_DIR=$DATA_DIR" >&2
    echo "DATA_DIR_ABS=$DATA_DIR_ABS" >&2
    echo "" >&2
    echo "Fix (recommended):" >&2
    echo "  sudo chown -R \"$(id -u):$(id -g)\" \"$DATA_DIR_ABS\"" >&2
    return 1
  fi
}

_project_core_explain_log_dir_permission_fix() {
  local target_dir="$1"
  echo "" >&2
  echo "Permission fix (recommended):" >&2
  echo "  sudo chown -R \"$(id -u):$(id -g)\" \"$target_dir\"" >&2
  echo "Or relax permissions (less strict):" >&2
  echo "  chmod u+rwX \"$target_dir\"" >&2
}

# Safety: runtime data must live outside the repo working tree.
case "$DATA_DIR_ABS" in
  "$BASE_DIR" | "$BASE_DIR"/*)
    echo "Aborting: DATA_DIR must not be inside BASE_DIR." >&2
    echo "BASE_DIR=$BASE_DIR" >&2
    echo "DATA_DIR=$DATA_DIR" >&2
    echo "DATA_DIR_ABS=$DATA_DIR_ABS" >&2
    return 1
    ;;
esac

_project_core_init_log() {
  if [ -n "${_PROJECT_CORE_LOG_INITIALIZED:-}" ]; then
    return 0
  fi
  _PROJECT_CORE_LOG_INITIALIZED=1

  # The first non-common script in the source stack.
  local caller=""
  local candidate=""
  local i=1
  while [ $i -lt ${#BASH_SOURCE[@]} ]; do
    candidate="${BASH_SOURCE[$i]}"
    if [[ "$candidate" == */scripts/common.sh ]] || [[ "$candidate" == */tooling/common.sh ]]; then
      i=$((i + 1))
      continue
    fi
    caller="$candidate"
    break
  done
  if [ -z "$caller" ]; then
    return 0
  fi
  local caller_abs
  caller_abs="$(cd "$(dirname "$caller")" && pwd)/$(basename "$caller")"

  local rel_path="$caller_abs"
  if [[ "$caller_abs" == "$BASE_DIR/"* ]]; then
    rel_path="${caller_abs#"$BASE_DIR/"}"
  else
    rel_path="$(basename "$caller_abs")"
  fi
  SCRIPT_ABS_PATH="$caller_abs"
  SCRIPT_REL_PATH="$rel_path"

  local rel_dir
  rel_dir="$(dirname "$rel_path")"
  if [ "$rel_dir" = "." ]; then
    rel_dir=""
  fi

  local log_dir="${LOG_DIR_ABS}"
  if [ -n "$rel_dir" ]; then
    log_dir="${log_dir}/${rel_dir}"
  fi
  if ! mkdir -p "$log_dir"; then
    echo "Aborting: could not create log directory: $log_dir" >&2
    echo "BASE_DIR=$BASE_DIR" >&2
    echo "LOG_DIR_ABS=$LOG_DIR_ABS" >&2
    _project_core_explain_log_dir_permission_fix "$LOG_DIR_ABS"
    return 1
  fi
  if [ ! -w "$log_dir" ]; then
    echo "Aborting: log directory is not writable by current user: $log_dir" >&2
    echo "BASE_DIR=$BASE_DIR" >&2
    echo "LOG_DIR_ABS=$LOG_DIR_ABS" >&2
    _project_core_explain_log_dir_permission_fix "$log_dir"
    return 1
  fi

  local base_name
  base_name="$(basename "$rel_path")"
  local run_stamp
  run_stamp="$(date +%Y%m%d-%H%M%S 2>/dev/null || date +%s)"
  LOG_PATH="${log_dir}/${base_name}.${run_stamp}.$$.log"

  # Start a fresh log on each run and mirror output to console.
  if ! : >"$LOG_PATH" 2>/dev/null; then
    echo "Aborting: could not write log file: $LOG_PATH" >&2
    echo "BASE_DIR=$BASE_DIR" >&2
    echo "LOG_DIR_ABS=$LOG_DIR_ABS" >&2
    _project_core_explain_log_dir_permission_fix "$log_dir"
    return 1
  fi

  # Keep only the 10 most recent logs for this command.
  local old_logs
  old_logs="$(ls -1t "${log_dir}/${base_name}."*.log 2>/dev/null || true)"
  if [ -n "$old_logs" ]; then
    echo "$old_logs" | sed -n '11,$p' | xargs -r rm -f --
  fi

  # Symlink to the latest command log in its directory.
  ln -sfn "$(basename "$LOG_PATH")" "${log_dir}/${base_name}.latest.log"
  # Global symlink to the latest generated log (any command).
  local latest_target_rel
  if [[ "$LOG_PATH" == "$LOG_DIR_ABS/"* ]]; then
    latest_target_rel="${LOG_PATH#"$LOG_DIR_ABS/"}"
  else
    latest_target_rel="$(basename "$LOG_PATH")"
  fi
  ln -sfn "$latest_target_rel" "${LOG_DIR_ABS}/latest.log"

  # Preserve original terminal streams so callers can bypass tee temporarily.
  exec 3>&1 4>&2
  exec > >(tee "$LOG_PATH") 2>&1
}

# Run a command bypassing the tee redirection created by common.sh.
# Useful for interactive tools (e.g. docker compose) that should own the terminal.
project_core_run_without_tee() {
  if [ -n "${LOG_PATH:-}" ]; then
    "$@" 1>&3 2>&4
    return $?
  fi
  "$@"
}

# Capture stdout while still bypassing tee for stderr (to keep interactive errors visible).
project_core_capture_without_tee() {
  if [ -n "${LOG_PATH:-}" ]; then
    "$@" 2>&4
    return $?
  fi
  "$@"
}

_project_core_init_log

_project_core_emit_header_line() {
  local line="$1"
  # For project entrypoints, keep header only in LOG_PATH (not in terminal output).
  if { [ "${SCRIPT_REL_PATH:-}" = "project.sh" ] || [ "${SCRIPT_REL_PATH:-}" = "scripts/project.sh" ]; } && [ -n "${LOG_PATH:-}" ]; then
    echo "$line" >>"$LOG_PATH"
    return 0
  fi
  echo "$line"
}

_project_core_emit_header_line "RUN_AT=$(date -Is 2>/dev/null || date)"

if [ -n "${SCRIPT_REL_PATH:-}" ]; then
  cmdline="$(printf '%q' "$SCRIPT_REL_PATH")"
  for arg in "$@"; do
    cmdline+=" $(printf '%q' "$arg")"
  done
  _project_core_emit_header_line "CMDLINE=${cmdline}"
fi

_project_core_emit_header_line "BASE_DIR=${BASE_DIR}"
_project_core_emit_header_line "DATA_DIR=${DATA_DIR}"
_project_core_emit_header_line "DATA_DIR_ABS=${DATA_DIR_ABS}"
_project_core_emit_header_line "LOG_DIR=${LOG_DIR}"
_project_core_emit_header_line "LOG_DIR_ABS=${LOG_DIR_ABS}"
_project_core_emit_header_line "PRIVATE_DIR=${PRIVATE_DIR}"
_project_core_emit_header_line "LOG_PATH=${LOG_PATH:-}"

if command -v id >/dev/null 2>&1; then
  _project_core_emit_header_line "USER_UID=$(id -u)"
  _project_core_emit_header_line "USER_GID=$(id -g)"
fi

project_core_env_init() {
  # Optional hook for downstream projects.
  :
}

# Optional downstream extensions; keep project-core independent.
if [ -f "${BASE_DIR}/scripts/common.local.sh" ]; then
  # shellcheck source=/dev/null
  source "${BASE_DIR}/scripts/common.local.sh"
fi
