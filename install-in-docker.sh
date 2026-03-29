#!/usr/bin/env bash
# Docker build wrapper for k-orchestrator raw plugin bundle staging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
TARGET="${1:-/opt/k-orchestrator}"
TEMP_DIR="$(mktemp -d "$SCRIPT_DIR/.tmp-docker.XXXXXX")"
STAGE_DIR="$(mktemp -d "$SCRIPT_DIR/.tmp-bundle.XXXXXX")"
MARKER_FILE=".k-orchestrator-bundle"

cleanup() {
  rm -rf "$TEMP_DIR"
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

safe_target_or_die() {
  local target_abs parent_abs
  parent_abs="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd -P)"
  if [ -z "$parent_abs" ]; then
    echo "ERROR: parent directory does not exist: $(dirname "$TARGET")" >&2
    exit 1
  fi
  target_abs="$parent_abs/$(basename "$TARGET")"

  case "$target_abs" in
    ''|/|/opt|/tmp*|/var*|/usr*|/bin*|/sbin*|/etc*|/System*|/Library*|/proc*|/sys*|/dev*|/private*|/run*|/boot*)
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

# Atomic swap — 기존 번들 백업 후 교체, 실패 시 복구
BACKUP_DIR=""
if [ -d "$TARGET" ]; then
  BACKUP_DIR="${TARGET}.bak.$$"
  mv "$TARGET" "$BACKUP_DIR"
fi

if mv "$STAGE_DIR" "$TARGET"; then
  [ -n "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
else
  echo "ERROR: bundle 이동 실패 — 복구 시도" >&2
  if [ -n "$BACKUP_DIR" ]; then
    if ! mv "$BACKUP_DIR" "$TARGET"; then
      echo "CRITICAL: 복구 실패 — 수동 확인 필요: $BACKUP_DIR" >&2
    fi
  fi
  exit 1
fi

echo "✅ k-orchestrator Docker 설치 완료: $TARGET"
find "$TARGET" -maxdepth 2 -type f | sort >&2
