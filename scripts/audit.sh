#!/usr/bin/env bash
set -uo pipefail
export LC_ALL=C

PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "[OK] $desc"
        ((PASS+=1))
    else
        echo "[FAIL] $desc: expected=$expected actual=$actual"
        ((FAIL+=1))
    fi
}

sudo -v || exit 1
SSH_CONFIG=$(sudo /usr/sbin/sshd -T) || exit 1
UFW_STATUS=$(sudo ufw status verbose) || exit 1

echo "Audit: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] SSH"
check "Root login disabled" "no" \
    "$(awk '$1=="permitrootlogin"{print $2}' <<< "$SSH_CONFIG")"

check "Password login disabled" "no" \
    "$(awk '$1=="passwordauthentication"{print $2}' <<< "$SSH_CONFIG")"

PORTS=$(awk '$1=="port"{print $2}' <<< "$SSH_CONFIG")
NONSTANDARD=no
if [[ -n "$PORTS" ]] && ! grep -qx '22' <<< "$PORTS"; then
    NONSTANDARD=yes
fi
check "SSH ports exclude 22" "yes" "$NONSTANDARD"

check "MaxAuthTries equals 3" "3" \
    "$(awk '$1=="maxauthtries"{print $2}' <<< "$SSH_CONFIG")"

echo "[2] Firewall"
check "UFW active" "active" \
    "$(awk '/^Status:/{print $2}' <<< "$UFW_STATUS")"

check "Default incoming policy deny" "deny" \
    "$(sed -n 's/^Default: \([^ ]*\) (incoming).*/\1/p' <<< "$UFW_STATUS")"

echo "[3] Users"
awk -F: '$3>=1000 && $3<65534 {
    printf "  %s (uid=%s)\n", $1, $3
}' /etc/passwd

echo "Passed: $PASS; failed: $FAIL"
if [[ "$FAIL" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
