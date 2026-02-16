#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_SH_DIR="${BASE_DIR}/tooling/project.sh"
PROJECT_MODULES_DIR="${BASE_DIR}/scripts/project"
PROJECT_MODULES_CONF="${PROJECT_MODULES_DIR}/modules.conf"

if [ ! -f "${PROJECT_SH_DIR}/scripts/common.sh" ]; then
  echo "Missing project.sh runtime at ${PROJECT_SH_DIR}." >&2
  echo "Install it with: ./scripts/project-core/install.sh" >&2
  exit 1
fi

cd "$BASE_DIR"
source "${PROJECT_SH_DIR}/scripts/common.sh"
source "${PROJECT_SH_DIR}/scripts/project/.infra/common.sh"
source "${PROJECT_SH_DIR}/scripts/project/.infra/modules.sh"
source "${PROJECT_SH_DIR}/scripts/project/.infra/entrypoint.sh"
helper_modules_bootstrap "${PROJECT_MODULES_DIR}" "${PROJECT_MODULES_CONF}"

main "$@"
