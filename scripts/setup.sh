#!/usr/bin/env bash
# Usage: ./scripts/setup.sh [--force] /path/to/your/repo
# Copies opencode-wiki into a 'wiki/' subdirectory of your project
# and sets up the OpenCode plugin at the project root.

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FORCE=0

usage() {
  echo "Usage: $0 [--force] /path/to/your/project"
  echo ""
  echo "Example: $0 ~/projects/trading-bot"
}

confirm_replacements() {
  local -a replacements=("$@")
  local path

  if [ ${#replacements[@]} -eq 0 ]; then
    return 0
  fi

  echo "Warning: setup will replace or merge into existing opencode-wiki files:"
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

TARGET="$(cd "$1" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET does not exist"
  exit 1
fi

echo "Setting up opencode-wiki in $TARGET/wiki/"

declare -a REPLACEMENTS=()
for rel_path in \
  "wiki/AGENTS.md" \
  "wiki/opencode.json" \
  "wiki/pyproject.toml" \
  "wiki/scripts" \
  "wiki/daily" \
  "wiki/knowledge" \
  ".opencode/plugins/opencode-wiki.js" \
  ".opencode/plugins/llm-wiki.js" \
  ".opencode/package.json"; do
  if [ -e "$TARGET/$rel_path" ]; then
    REPLACEMENTS+=("$TARGET/$rel_path")
  fi
done

if [ -f "$TARGET/opencode.json" ]; then
  echo "Warning: $TARGET/opencode.json already exists and will not be replaced."
  echo "  Make sure it has 'instructions' pointing to wiki/AGENTS.md:"
  echo '    "instructions": ["wiki/AGENTS.md"]'
  echo ""
fi

confirm_replacements "${REPLACEMENTS[@]}"

# 1. Copy wiki files into wiki/ subdirectory
mkdir -p "$TARGET/wiki"
cp -r "$WIKI_DIR/AGENTS.md" "$TARGET/wiki/"
cp -r "$WIKI_DIR/opencode.json" "$TARGET/wiki/"
cp -r "$WIKI_DIR/pyproject.toml" "$TARGET/wiki/"
cp -r "$WIKI_DIR/scripts" "$TARGET/wiki/"
cp -r "$WIKI_DIR/daily" "$TARGET/wiki/"
cp -r "$WIKI_DIR/knowledge" "$TARGET/wiki/"

# 2. Copy plugin to project root .opencode/
mkdir -p "$TARGET/.opencode/plugins"
rm -f "$TARGET/.opencode/plugins/llm-wiki.js"
cp "$WIKI_DIR/.opencode/plugins/opencode-wiki.js" "$TARGET/.opencode/plugins/"
cp "$WIKI_DIR/.opencode/package.json" "$TARGET/.opencode/"

# 3. Install plugin dependencies
if [ -d "$TARGET/.opencode/node_modules" ]; then
  echo "Plugin dependencies already installed"
else
  echo "Installing plugin dependencies..."
  cd "$TARGET/.opencode" && npm install --silent
fi

# 4. Create opencode.json at project root (if not exists)
if [ -f "$TARGET/opencode.json" ]; then
  echo "Root opencode.json already exists. Skipping creation."
else
  cat > "$TARGET/opencode.json" << 'EOF'
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
  echo "Created $TARGET/opencode.json"
fi

echo ""
echo "Done! Project structure:"
echo ""
echo "  $TARGET/"
echo "    opencode.json          # OpenCode config (points to wiki/)"
echo "    .opencode/"
echo "      plugins/opencode-wiki.js  # Plugin"
echo "    wiki/"
echo "      AGENTS.md            # Wiki compiler spec"
echo "      daily/               # Session logs"
echo "      knowledge/           # Compiled wiki"
echo "      scripts/             # Python scripts"
echo ""
echo "Run 'opencode' from $TARGET to start using the wiki."
