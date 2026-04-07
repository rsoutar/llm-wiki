# LLM Wiki for OpenCode

OpenCode conversations compile themselves into a persistent Markdown wiki. This gives OpenCode a two-tier memory system that retains knowledge across sessions.

This project adapts Andrej Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) to OpenCode. Instead of treating each conversation as disposable chat history, it captures meaningful session deltas into daily logs and compiles those logs into a maintained knowledge base. The compiled wiki is injected back into future sessions, creating persistent memory.

## What It Does

```text
OpenCode session
  -> .opencode/plugins/llm-wiki.js captures new transcript deltas
  -> scripts/flush.py summarizes them into daily/YYYY-MM-DD.md
  -> scripts/compile.py compiles daily logs into knowledge/*
  -> scripts/query.py answers questions from the wiki
  -> scripts/lint.py checks wiki health
```

The result is a lightweight memory layer for OpenCode:

- `daily/` stores append-only raw session logs
- `knowledge/` stores compiled concepts, connections, and filed Q&A
- `knowledge/index.md` becomes the main retrieval surface for future chats

## How Memory Works

This project gives OpenCode persistent memory across sessions through a two-tier system.

### Tier 1: Raw Memory (`daily/`)

Append-only logs capturing meaningful session deltas.

- Automatically written when you idle after a conversation
- The LLM decides what has durable value vs disposable chat

### Tier 2: Compiled Knowledge (`knowledge/`)

Daily logs are compiled into structured wiki articles.

- One article per concept, pattern, decision, or lesson
- Connection pages capture non-obvious cross-cutting insights
- `knowledge/index.md` becomes the retrieval surface

### Memory Lifecycle

```text
Session ──> Capture ──> Daily Log ──> Compile ──> Knowledge
  ^                                                        │
  └──────────────── Inject context back ───────────────────┘
```

```text
┌─────────────────────────────────────────────────────────────────┐
│                        OpenCode Session                         │
│  (reads knowledge/index.md + recent daily logs on startup)      │
└──────────────────────────┬──────────────────────────────────────┘
                           │  session idle
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  .opencode/plugins/llm-wiki.js                                  │
│  captures new transcript delta, runs scripts/flush.py           │
└──────────────────────────┬──────────────────────────────────────┘
                           │  if durable value
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  daily/YYYY-MM-DD.md                                            │
│  append-only raw session log                                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │  compile (manual or auto after 6 PM)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  knowledge/                                                     │
│  concepts/, connections/, qa/, index.md                         │
└─────────────────────────────────────────────────────────────────┘
```

### How It Feeds Back

- `knowledge/index.md` is injected into every new session's system prompt
- Recent daily logs provide fresh context
- This lets OpenCode "remember" your patterns, decisions, and preferences

### Preventing Recursive Capture

Internal maintenance runs set `OPENCODE_MEMORY_INTERNAL=1` so the capture plugin does not trigger during compile, query, or lint operations. This prevents the system from recording itself.

### Automatic Behavior

What happens automatically after installation:

- On chat idle, the plugin captures the new part of the conversation
- If the transcript has durable value, it appends an entry to `daily/YYYY-MM-DD.md`
- The plugin injects `knowledge/index.md` and recent daily-log context back into future sessions

Compilation behavior:

- `daily/` capture is automatic
- `knowledge/` compilation can auto-run after `6:00 PM` local time when a successful flush changed the current daily log
- If you want compilation immediately, run it manually

## Repository Layout

```text
.
├── AGENTS.md
├── daily/
├── knowledge/
├── opencode.json
├── scripts/
└── .opencode/plugins/llm-wiki.js
```

## Requirements

- [OpenCode](https://opencode.ai/)
- Python 3.11+
- [`uv`](https://docs.astral.sh/uv/)
- `npm`

## Local Development

```bash
uv sync
npm install --prefix .opencode
```

Then open this repo in OpenCode.

Project config lives in [`opencode.json`](/Users/rsoutar/Projects/rsoutar/llm-wiki/opencode.json) and the compiler schema lives in [`AGENTS.md`](/Users/rsoutar/Projects/rsoutar/llm-wiki/AGENTS.md).

## Install Into Another Repo

The easiest path is the setup script:

```bash
./scripts/setup.sh /path/to/your/project
```

That creates this structure inside the target project:

```text
your-project/
├── opencode.json
├── .opencode/plugins/llm-wiki.js
└── wiki/
    ├── AGENTS.md
    ├── daily/
    ├── knowledge/
    └── scripts/
```

Then run OpenCode from the target project root, not from `wiki/`.

## Commands

```bash
uv run python scripts/compile.py
uv run python scripts/compile.py --all
uv run python scripts/compile.py --file daily/2026-04-07.md
uv run python scripts/query.py "What patterns do I keep using for auth?"
uv run python scripts/query.py "How do I tend to structure background jobs?" --file-back
uv run python scripts/lint.py
uv run python scripts/lint.py --structural-only
```

## How To Use It

1. Work normally in OpenCode.
2. Let `daily/` accumulate session logs automatically.
3. Compile into `knowledge/` periodically, or let evening auto-compile pick it up.
4. Ask future questions in the same repo and let the wiki context feed back into the session.

## Troubleshooting

If `daily/` is not updating:

- Make sure you launched OpenCode from the project root that contains `opencode.json`.
- Check `.opencode/plugins/llm-wiki.js` exists in the target project.
- Check `wiki/scripts/flush.log` and `wiki/.opencode/flush-errors.log` in the installed project.
- Make sure `npm install` has been run inside the target project's `.opencode/`.

If `knowledge/` is not updating:

- Run `uv run python scripts/compile.py` manually once to confirm the compile path works.
- Remember that automatic compile is time-gated to after `6:00 PM` local time.

## Open Source Checklist

Before publishing, the main remaining non-code items are:

- License: Apache 2.0
- Add a short GitHub description and topics
- Add one real example or screenshot of `daily/` and `knowledge/`
- Optionally add `CONTRIBUTING.md` once you want outside patches

## Notes

- Automatic capture happens through the local OpenCode plugin in `.opencode/plugins/`.
- Internal maintenance runs set `OPENCODE_MEMORY_INTERNAL=1` so they do not recursively trigger the capture plugin.
- The wiki works best when `knowledge/index.md` stays compact and high-signal.
