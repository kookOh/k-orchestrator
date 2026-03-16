#!/usr/bin/env bash
# Docker build wrapper for k-orchestrator raw plugin bundle staging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-/opt/k-orchestrator}"
TEMP_DIR="$(mktemp -d /tmp/k-orchestrator-docker.XXXXXX)"
STAGE_DIR="$(mktemp -d /tmp/k-orchestrator-bundle.XXXXXX)"
MARKER_FILE=".k-orchestrator-bundle"

cleanup() {
  rm -rf "$TEMP_DIR"
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

safe_target_or_die() {
  local target_abs parent_abs
  parent_abs="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)"
  if [ -z "$parent_abs" ]; then
    echo "ERROR: parent directory does not exist: $(dirname "$TARGET")" >&2
    exit 1
  fi
  target_abs="$parent_abs/$(basename "$TARGET")"

  case "$target_abs" in
    ''|/|/opt|/tmp|/var|/usr|/bin|/sbin|/System|/Library)
      echo "ERROR: unsafe Docker target: $target_abs" >&2
      exit 1
      ;;
  esac

  if [ -e "$target_abs" ] && [ ! -d "$target_abs" ]; then
    echo "ERROR: target exists and is not a directory: $target_abs" >&2
    exit 1
  fi

  if [ -d "$target_abs" ] && [ -n "$(find "$target_abs" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ] && [ ! -f "$target_abs/$MARKER_FILE" ]; then
    echo "ERROR: refusing to replace non-bundle directory: $target_abs" >&2
    exit 1
  fi

  TARGET="$target_abs"
}

echo "▶ k-orchestrator Docker 설치"
echo "  source: $SCRIPT_DIR"
echo "  target: $TARGET"

safe_target_or_die

# Run the existing installer into a safe temp project to preserve its contract.
bash "$SCRIPT_DIR/install.sh" "$TEMP_DIR" >/dev/null

mkdir -p "$STAGE_DIR/commands" "$STAGE_DIR/skills" "$STAGE_DIR/templates" "$STAGE_DIR/hooks"

# Commands/skills are staged from the temp install result so the Docker bundle follows the install contract.
cp -R "$TEMP_DIR/.claude/commands/k-orchestrator/." "$STAGE_DIR/commands/"
cp -R "$TEMP_DIR/.claude/skills/k-orchestrator/." "$STAGE_DIR/skills/"
# Templates remain source assets because install.sh materializes them into a project, not a raw bundle.
cp -R "$SCRIPT_DIR/templates/." "$STAGE_DIR/templates/"

if [ -d "$SCRIPT_DIR/hooks" ]; then
  cp -R "$SCRIPT_DIR/hooks/." "$STAGE_DIR/hooks/"
  chmod +x "$STAGE_DIR/hooks/"*.sh 2>/dev/null || true
fi

touch "$STAGE_DIR/$MARKER_FILE"
find "$STAGE_DIR" -name .DS_Store -delete 2>/dev/null || true

mkdir -p "$(dirname "$TARGET")"
if [ -d "$TARGET" ]; then
  rm -rf "$TARGET"
fi
mv "$STAGE_DIR" "$TARGET"
mkdir -p "$STAGE_DIR"

echo "✅ k-orchestrator Docker 설치 완료: $TARGET"
find "$TARGET" -maxdepth 2 -type f | sort
