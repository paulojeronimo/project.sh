#!/usr/bin/env sh
set -eu

PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
PROJECT_SH_REPO="${PROJECT_SH_REPO:-https://github.com/paulojeronimo/project.sh.git}"
PROJECT_SH_REF="${PROJECT_SH_REF:-9a3606a6773d752de76d04c109d4a04b08ee1224}"
PROJECT_SH_PIN_DIR="${PROJECT_SH_PIN_DIR:-scripts/project-core}"
PROJECT_SH_PIN_FILE="${PROJECT_ROOT}/${PROJECT_SH_PIN_DIR}/pin.env"
PROJECT_SH_INSTALL_FILE="${PROJECT_ROOT}/${PROJECT_SH_PIN_DIR}/install.sh"
PROJECT_SH_ENTRYPOINT_FILE="${PROJECT_ROOT}/scripts/project.sh"
PROJECT_SH_ROOT_LINK="${PROJECT_ROOT}/project.sh"
PROJECT_SH_RUNTIME_DIR="${PROJECT_SH_DEST_DIR:-${PROJECT_ROOT}/tooling/project.sh}"

mkdir -p "${PROJECT_ROOT}/${PROJECT_SH_PIN_DIR}"

cat >"${PROJECT_SH_PIN_FILE}" <<EOF_PIN
PROJECT_SH_REPO="${PROJECT_SH_REPO}"
PROJECT_SH_REF="${PROJECT_SH_REF}"
EOF_PIN

cat >"${PROJECT_SH_INSTALL_FILE}" <<'EOF_INSTALL'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEST_DIR="${PROJECT_SH_DEST_DIR:-${BASE_DIR}/tooling/project.sh}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/pin.env"

rm -rf "${DEST_DIR}"
git clone "${PROJECT_SH_REPO}" "${DEST_DIR}" >/dev/null 2>&1
(
  cd "${DEST_DIR}"
  git checkout "${PROJECT_SH_REF}" >/dev/null 2>&1
)

echo "project.sh installed: ${DEST_DIR}"
echo "repo=${PROJECT_SH_REPO}"
echo "ref=${PROJECT_SH_REF}"
EOF_INSTALL

chmod +x "${PROJECT_SH_INSTALL_FILE}"

if [ "${PROJECT_SH_SKIP_INSTALL:-0}" != "1" ]; then
  (cd "${PROJECT_ROOT}" && "${PROJECT_SH_INSTALL_FILE}")
fi

# Install generic project.sh entrypoint from runtime template when available.
if [ -f "${PROJECT_SH_RUNTIME_DIR}/scripts/project.sh" ]; then
  if [ "${PROJECT_SH_OVERWRITE_ENTRYPOINT:-0}" = "1" ] || [ ! -f "${PROJECT_SH_ENTRYPOINT_FILE}" ]; then
    mkdir -p "${PROJECT_ROOT}/scripts"
    cp "${PROJECT_SH_RUNTIME_DIR}/scripts/project.sh" "${PROJECT_SH_ENTRYPOINT_FILE}"
    chmod +x "${PROJECT_SH_ENTRYPOINT_FILE}"
  fi
fi

# Ensure root shortcut points to scripts/project.sh.
if [ -L "${PROJECT_SH_ROOT_LINK}" ] || [ ! -e "${PROJECT_SH_ROOT_LINK}" ]; then
  ln -sfn "scripts/project.sh" "${PROJECT_SH_ROOT_LINK}"
fi

echo "Pinned project.sh in: ${PROJECT_SH_PIN_FILE}"
echo "Installer created at: ${PROJECT_SH_INSTALL_FILE}"
echo "To reinstall later: ./${PROJECT_SH_PIN_DIR}/install.sh"
