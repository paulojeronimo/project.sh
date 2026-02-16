#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_MODULES_DIR="${BASE_DIR}/scripts/project"
PROJECT_MODULES_CONF="${PROJECT_MODULES_DIR}/modules.conf"

cd "$BASE_DIR"
source "${BASE_DIR}/scripts/common.sh"
source "${BASE_DIR}/scripts/project/.infra/common.sh"
source "${BASE_DIR}/scripts/project/.infra/modules.sh"
source "${BASE_DIR}/scripts/project/.infra/help.sh"
source "${BASE_DIR}/scripts/project/.infra/entrypoint.sh"
helper_modules_bootstrap "${PROJECT_MODULES_DIR}" "${PROJECT_MODULES_CONF}"
helper_help_bootstrap
helper_help_validate_for_modules "${PROJECT_MODULES_CONF}"

main "$@"
