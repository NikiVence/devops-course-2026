#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

DRY_RUN=false
case "${1:-}" in
    "") ;;
    --dry-run) DRY_RUN=true ;;
    *) fail "Usage: scripts/deploy.sh [--dry-run]" ;;
esac
[[ $# -le 1 ]] || fail "Too many arguments"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
LOCAL_DIR="$ROOT/site/"
REMOTE="devops"
REMOTE_DIR="/var/www/devops-site/"
CA_CERT="$HOME/devops.crt"
SITE_URL="https://devops.local/"
SERVER_IP="192.168.247.101"

[[ -f "${LOCAL_DIR}index.html" ]] ||
    fail "site/index.html is missing"

STATUS="$(git -C "$ROOT" status --porcelain --untracked-files=all)"
[[ -z "$STATUS" ]] ||
    fail "Working tree is not clean; commit changes first"

[[ -r "$CA_CERT" ]] ||
    fail "Certificate not found: $CA_CERT"

COMMIT="$(git -C "$ROOT" rev-parse --short HEAD)"
OPTIONS=(-avz --delete --chmod=D755,F644)

if "$DRY_RUN"; then
    OPTIONS+=(--dry-run)
fi

rsync "${OPTIONS[@]}" \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    "$LOCAL_DIR" "${REMOTE}:${REMOTE_DIR}" ||
    fail "rsync failed"

if "$DRY_RUN"; then
    echo "Dry run OK; commit: $COMMIT"
    exit 0
fi

curl --noproxy "*" \
    --resolve "devops.local:443:$SERVER_IP" \
    --cacert "$CA_CERT" \
    --connect-timeout 5 --max-time 15 \
    --fail --silent --show-error \
    "$SITE_URL" >/dev/null ||
    fail "HTTPS check failed"

echo "Deploy OK; commit: $COMMIT"
