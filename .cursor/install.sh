#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace"
APP_DIR="${ROOT}/Ecommerce-Website-main"
ZIP="${ROOT}/Ecommerce-Website-main.zip"

cd "${ROOT}"

if [[ ! -d "${APP_DIR}/client" || ! -d "${APP_DIR}/server" ]]; then
  if [[ ! -f "${ZIP}" ]]; then
    echo "Missing ${ZIP}; cannot prepare the ecommerce application." >&2
    exit 1
  fi
  unzip -q -o "${ZIP}" -d "${ROOT}"
fi

if [[ -f "${APP_DIR}/package-lock.json" ]]; then
  npm ci --prefix "${APP_DIR}" --no-audit --no-fund
else
  npm install --prefix "${APP_DIR}" --no-audit --no-fund
fi

npm ci --prefix "${APP_DIR}/client" --no-audit --no-fund
npm ci --prefix "${APP_DIR}/server" --no-audit --no-fund

PATCH_FILE="${ROOT}/.cursor/patches/server-supabase-null-guard.patch"
if [[ -f "${PATCH_FILE}" ]]; then
  (cd "${APP_DIR}" && patch -p1 -N -s -i "${PATCH_FILE}") || true
fi

if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_API_KEY:-}" ]]; then
  printf 'SUPABASE_URL=%s\nSUPABASE_API_KEY=%s\n' "${SUPABASE_URL}" "${SUPABASE_API_KEY}" \
    > "${APP_DIR}/server/.env"
fi
