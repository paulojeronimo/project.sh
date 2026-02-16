#!/usr/bin/env sh
set -eu

PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
PROJECT_CORE_REPO="${PROJECT_CORE_REPO:-https://github.com/paulojeronimo/project.sh.git}"
PROJECT_CORE_REF="${PROJECT_CORE_REF:-9a3606a6773d752de76d04c109d4a04b08ee1224}"
PROJECT_CORE_PIN_DIR="${PROJECT_CORE_PIN_DIR:-scripts/project-core}"
PROJECT_CORE_PIN_FILE="${PROJECT_ROOT}/${PROJECT_CORE_PIN_DIR}/pin.env"
PROJECT_CORE_INSTALL_FILE="${PROJECT_ROOT}/${PROJECT_CORE_PIN_DIR}/install.sh"

mkdir -p "${PROJECT_ROOT}/${PROJECT_CORE_PIN_DIR}"

cat >"${PROJECT_CORE_PIN_FILE}" <<EOF_PIN
PROJECT_CORE_REPO="${PROJECT_CORE_REPO}"
PROJECT_CORE_REF="${PROJECT_CORE_REF}"
EOF_PIN

cat >"${PROJECT_CORE_INSTALL_FILE}" <<'EOF_INSTALL'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEST_DIR="${PROJECT_CORE_DEST_DIR:-${BASE_DIR}/tooling/project-core}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/pin.env"

rm -rf "${DEST_DIR}"
git clone "${PROJECT_CORE_REPO}" "${DEST_DIR}" >/dev/null 2>&1
(
  cd "${DEST_DIR}"
  git checkout "${PROJECT_CORE_REF}" >/dev/null 2>&1
)

echo "project-core installed: ${DEST_DIR}"
echo "repo=${PROJECT_CORE_REPO}"
echo "ref=${PROJECT_CORE_REF}"
EOF_INSTALL

chmod +x "${PROJECT_CORE_INSTALL_FILE}"

if [ "${PROJECT_CORE_SKIP_INSTALL:-0}" != "1" ]; then
  (cd "${PROJECT_ROOT}" && "${PROJECT_CORE_INSTALL_FILE}")
fi

echo "Pinned project-core in: ${PROJECT_CORE_PIN_FILE}"
echo "Installer created at: ${PROJECT_CORE_INSTALL_FILE}"
echo "To reinstall later: ./${PROJECT_CORE_PIN_DIR}/install.sh"
