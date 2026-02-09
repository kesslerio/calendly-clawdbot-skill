#!/usr/bin/env bash
set -euo pipefail

CURRENT="${CURRENT:-./calendly}"
OPENAPI="${OPENAPI:-./generated/openapi/calendly_openapi.py}"
COMPAT="${COMPAT:-./calendly-openapi-compat}"
REPORT="${REPORT:-./reports/openapi-parity.txt}"

if [[ ! -x "$CURRENT" ]]; then
  echo "Current CLI not executable: $CURRENT" >&2
  exit 1
fi
if [[ ! -f "$OPENAPI" ]]; then
  echo "OpenAPI CLI missing: $OPENAPI" >&2
  exit 1
fi
if [[ ! -x "$COMPAT" ]]; then
  echo "Compat CLI not executable: $COMPAT" >&2
  exit 1
fi

mkdir -p "$(dirname "$REPORT")"

required_current=(
  "get-current-user"
  "list-events"
  "list-events-with-invitees"
  "get-event"
  "cancel-event"
  "list-event-invitees"
  "list-organization-memberships"
)

openapi_expected=(
  "users get-user-account"
  "scheduled-events get-events"
  "scheduled-events get-uuid"
  "scheduled-events get"
  "organizations get-memberships"
)

compat_expected=(
  "get-current-user"
  "list-events"
  "list-events-with-invitees"
  "get-event"
  "cancel-event"
  "list-event-invitees"
  "list-organization-memberships"
)

missing=0

{
  echo "OpenAPI parity report"
  echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "Current CLI required commands:"
  for c in "${required_current[@]}"; do
    if "$CURRENT" "$c" --help >/dev/null 2>&1; then
      echo "  [OK] $c"
    else
      echo "  [MISSING] $c"
      missing=$((missing+1))
    fi
  done

  echo
  echo "Generated OpenAPI CLI expected equivalents:"
  for c in "${openapi_expected[@]}"; do
    if python "$OPENAPI" $c --help >/dev/null 2>&1; then
      echo "  [OK] $c"
    else
      echo "  [MISSING] $c"
      missing=$((missing+1))
    fi
  done

  echo
  echo "Compat wrapper command parity (legacy surface):"
  for c in "${compat_expected[@]}"; do
    if "$COMPAT" "$c" --help >/dev/null 2>&1; then
      echo "  [OK] $c"
    else
      echo "  [MISSING] $c"
      missing=$((missing+1))
    fi
  done

  echo
  echo "Compatibility notes:"
  echo "  - list-events-with-invitees is emulated via N+1 calls (event list + per-event invitees)"
  echo "  - cancel-event currently delegates to legacy CLI for behavior parity"

  if [[ $missing -eq 0 ]]; then
    echo
    echo "Structural parity check: PASS"
    echo "Default switch recommendation: READY_FOR_EXPERIMENTAL (use compat wrapper in non-critical flows first)"
  else
    echo
    echo "Structural parity check: FAIL ($missing missing commands)"
    echo "Default switch recommendation: HOLD"
  fi
} | tee "$REPORT"
