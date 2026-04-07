#!/usr/bin/env bash
# Usage: ./scripts/setup.sh /path/to/your/repo
# Copies llm-wiki into a 'wiki/' subdirectory of your project
# and sets up the OpenCode plugin at the project root.

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/your/project"
  echo ""
  echo "Example: $0 ~/projects/trading-bot"
  exit 1
fi

TARGET="$(cd "$1" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET does not exist"
  exit 1
fi

echo "Setting up llm-wiki in $TARGET/wiki/"

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
cp "$WIKI_DIR/.opencode/plugins/llm-wiki.js" "$TARGET/.opencode/plugins/"
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
  echo "Warning: $TARGET/opencode.json already exists. Skipping."
  echo "  Make sure it has 'instructions' pointing to wiki/AGENTS.md:"
  echo '    "instructions": ["wiki/AGENTS.md"]'
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
echo "      plugins/llm-wiki.js  # Plugin"
echo "    wiki/"
echo "      AGENTS.md            # Wiki compiler spec"
echo "      daily/               # Session logs"
echo "      knowledge/           # Compiled wiki"
echo "      scripts/             # Python scripts"
echo ""
echo "Run 'opencode' from $TARGET to start using the wiki."
