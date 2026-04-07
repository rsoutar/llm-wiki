#!/usr/bin/env bash
# Usage: ./scripts/upgrade.sh [--force] [--sync-root-config] /path/to/your/repo
# Upgrades opencode-wiki runtime files in an installed project without touching wiki data.

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FORCE=0
SYNC_ROOT_CONFIG=0

usage() {
  echo "Usage: $0 [--force] [--sync-root-config] /path/to/your/project"
  echo ""
  echo "Example: $0 ~/projects/trading-bot"
}

write_root_opencode() {
  local target_file="$1"
  cat > "$target_file" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["wiki/AGENTS.md"],
  "agent": {
    "knowledge-flush": {
      "description": "Summarize a recent OpenCode transcript delta into a durable daily-log entry",
      "prompt": "You maintain a personal knowledge base. Turn the supplied transcript delta into a structured daily-log entry. Return plain markdown only. Never use tools. Prefer saving a short entry whenever the transcript contains a concrete goal, debugging step, decision, lesson, or follow-up. Respond exactly FLUSH_OK only when the transcript is pure pleasantries, routine filler, or otherwise has no durable value.",
      "tools": { "bash": false, "write": false, "edit": false }
    },
    "knowledge-query": {
      "description": "Answer questions from the compiled wiki before anything else",
      "prompt": "Answer from the wiki described in AGENTS.md. Read knowledge/index.md first, then only the most relevant wiki pages. Cite wiki pages with [[wikilinks]]. If the wiki lacks the answer, say so plainly.",
      "tools": { "bash": false, "write": false, "edit": false }
    },
    "knowledge-linter": {
      "description": "Review the wiki for contradictions and inconsistencies",
      "prompt": "Review the wiki for contradictions, stale guidance, and inconsistent recommendations. Return only the issues the caller asked for. Use read-only tools only.",
      "tools": { "bash": false, "write": false, "edit": false }
    },
    "knowledge-compiler": {
      "description": "Compile daily conversation logs into a maintained markdown wiki",
      "prompt": "Maintain the wiki exactly as described in AGENTS.md. Prefer updating existing pages over creating duplicates. Always update knowledge/index.md and knowledge/log.md when the wiki changes."
    }
  }
}
EOF
}

confirm_replacements() {
  local -a replacements=("$@")
  local path

  if [ ${#replacements[@]} -eq 0 ]; then
    return 0
  fi

  echo "Warning: upgrade will replace existing opencode-wiki runtime files:"
  for path in "${replacements[@]}"; do
    echo "  - $path"
  done
  echo ""

  if [ "$FORCE" -eq 1 ]; then
    return 0
  fi

  if [ ! -t 0 ]; then
    echo "Non-interactive shell detected. Re-run with --force to continue."
    exit 1
  fi

  read -r -p "Continue? [y/N] " response
  case "$response" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    --sync-root-config)
      SYNC_ROOT_CONFIG=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: rsync is required for upgrades."
  exit 1
fi

TARGET="$(cd "$1" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET does not exist"
  exit 1
fi

if [ ! -d "$TARGET/wiki" ]; then
  echo "Error: $TARGET/wiki does not exist. Run setup.sh first."
  exit 1
fi

echo "Upgrading opencode-wiki in $TARGET/"

declare -a REPLACEMENTS=()
for rel_path in \
  "wiki/AGENTS.md" \
  "wiki/opencode.json" \
  "wiki/pyproject.toml" \
  "wiki/scripts" \
  ".opencode/plugins/opencode-wiki.js" \
  ".opencode/plugins/llm-wiki.js" \
  ".opencode/package.json"; do
  if [ -e "$TARGET/$rel_path" ]; then
    REPLACEMENTS+=("$TARGET/$rel_path")
  fi
done

if [ "$SYNC_ROOT_CONFIG" -eq 1 ] && [ -e "$TARGET/opencode.json" ]; then
  REPLACEMENTS+=("$TARGET/opencode.json")
elif [ -f "$TARGET/opencode.json" ]; then
  echo "Preserving $TARGET/opencode.json. Re-run with --sync-root-config to replace it too."
  echo ""
fi

# Bash 3.2 + `set -u` treats an empty array expansion as unbound, so guard it.
if [ ${#REPLACEMENTS[@]} -gt 0 ]; then
  confirm_replacements "${REPLACEMENTS[@]}"
fi

mkdir -p "$TARGET/wiki/scripts"
mkdir -p "$TARGET/.opencode/plugins"

cp "$WIKI_DIR/AGENTS.md" "$TARGET/wiki/"
cp "$WIKI_DIR/opencode.json" "$TARGET/wiki/"
cp "$WIKI_DIR/pyproject.toml" "$TARGET/wiki/"

rsync -a \
  --exclude 'state.json' \
  --exclude 'last-flush.json' \
  "$WIKI_DIR/scripts/" "$TARGET/wiki/scripts/"

rm -f "$TARGET/.opencode/plugins/llm-wiki.js"
cp "$WIKI_DIR/.opencode/plugins/opencode-wiki.js" "$TARGET/.opencode/plugins/"
cp "$WIKI_DIR/.opencode/package.json" "$TARGET/.opencode/"

if [ "$SYNC_ROOT_CONFIG" -eq 1 ]; then
  write_root_opencode "$TARGET/opencode.json"
elif [ ! -f "$TARGET/opencode.json" ]; then
  write_root_opencode "$TARGET/opencode.json"
  echo "Created $TARGET/opencode.json"
fi

if [ -f "$TARGET/.opencode/package.json" ]; then
  echo "Refreshing plugin dependencies..."
  (
    cd "$TARGET/.opencode"
    npm install --silent
  )
fi

echo ""
echo "Upgrade complete."
echo "Preserved data:"
echo "  - $TARGET/wiki/daily/"
echo "  - $TARGET/wiki/knowledge/"
echo "  - $TARGET/wiki/scripts/state.json"
echo "  - $TARGET/wiki/scripts/last-flush.json"
