#!/usr/bin/env bash
set -euo pipefail

OPENAPI2CLI_REPO="${OPENAPI2CLI_REPO:-/home/art/projects/skills/shared/openapi2cli-upstream}"
OPENAPI2CLI_COMMIT_EXPECTED="${OPENAPI2CLI_COMMIT_EXPECTED:-09f9b06c483cb7c26f571afd5516628237ff7839}"
CALENDLY_SPEC_URL="${CALENDLY_SPEC_URL:-https://raw.githubusercontent.com/robomotionio/openapi-specs/master/calendly.json}"
OUT_FILE="${OUT_FILE:-generated/openapi/calendly_openapi.py}"

if [[ ! -d "$OPENAPI2CLI_REPO/.git" ]]; then
  echo "openapi2cli repo not found at: $OPENAPI2CLI_REPO" >&2
  exit 1
fi

actual_commit="$(git -C "$OPENAPI2CLI_REPO" rev-parse HEAD)"
if [[ "$actual_commit" != "$OPENAPI2CLI_COMMIT_EXPECTED" ]]; then
  echo "Pinned openapi2cli commit mismatch" >&2
  echo " expected: $OPENAPI2CLI_COMMIT_EXPECTED" >&2
  echo " actual:   $actual_commit" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"

(
  cd "$OPENAPI2CLI_REPO"
  uv run openapi2cli generate "$CALENDLY_SPEC_URL" --name calendly_openapi --output "/home/art/projects/skills/work/calendly/$OUT_FILE"
)

chmod +x "$OUT_FILE"
python "$OUT_FILE" --help >/dev/null

echo "Generated: $OUT_FILE"
echo "Pinned openapi2cli commit: $actual_commit"
