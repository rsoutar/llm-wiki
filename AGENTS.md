# AGENTS.md - OpenCode Knowledge Compiler Schema

> Inspired by Andrej Karpathy's [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
> This repo adapts the pattern to OpenCode so conversations become a maintained markdown wiki.

## Core Idea

Treat OpenCode conversations as raw source material and compile them into a persistent wiki:

```text
daily/          = append-only source logs
OpenCode        = compiler + query engine
knowledge/      = compiled wiki
lint            = health checks
```

The raw sources are immutable. The wiki is LLM-owned. Humans browse, inspect, and redirect it, but the agent keeps the structure current.

## Layers

### 1. `daily/` - Raw Sources

`daily/YYYY-MM-DD.md` files are append-only logs created from OpenCode session deltas. A single day can contain multiple session entries.

Expected entry shape:

```markdown
### Session (14:30)

**Context:** What the user was trying to do.

**Key Exchanges:**
- Important question, answer, or discovery

**Decisions Made:**
- Decision and rationale

**Lessons Learned:**
- Gotcha, pattern, or reusable insight

**Action Items:**
- Follow-up work worth remembering
```

### 2. `knowledge/` - Compiled Wiki

This is the durable artifact. OpenCode owns this directory.

```text
knowledge/
  index.md
  log.md
  concepts/
  connections/
  qa/
```

- `index.md`: the primary retrieval surface. Read it first.
- `log.md`: chronological record of compile, query, and lint operations.
- `concepts/`: one article per concept, pattern, decision, or reusable lesson.
- `connections/`: non-obvious links between two or more concepts.
- `qa/`: filed answers generated from user queries.

### 3. `AGENTS.md` - The Compiler Spec

This file teaches OpenCode how to ingest, query, and maintain the wiki.

## Article Formats

### Concept Article

```markdown
---
title: "Concept Name"
aliases: [alternate-name]
tags: [topic]
sources:
  - "daily/2026-04-07.md"
created: 2026-04-07
updated: 2026-04-07
---

# Concept Name

[2-4 sentence summary]

## Key Points

- Self-contained point
- Self-contained point

## Details

[Encyclopedia-style explanation]

## Related Concepts

- [[concepts/related-concept]] - short reason

## Sources

- [[daily/2026-04-07.md]] - what this source contributed
```

### Connection Article

```markdown
---
title: "Connection: X and Y"
connects:
  - "concepts/x"
  - "concepts/y"
sources:
  - "daily/2026-04-07.md"
created: 2026-04-07
updated: 2026-04-07
---

# Connection: X and Y

## The Connection

[Explain the shared pattern or tension]

## Key Insight

[The distilled, non-obvious point]

## Evidence

[Specific examples from the source material]

## Related Concepts

- [[concepts/x]]
- [[concepts/y]]
```

### Filed Q&A Article

```markdown
---
title: "Q: Original Question"
question: "Original question"
consulted:
  - "concepts/example"
filed: 2026-04-07
---

# Q: Original Question

## Answer

[Answer with [[wikilinks]]]

## Sources Consulted

- [[concepts/example]] - why it mattered

## Follow-Up Questions

- Optional next question
```

## Operations

### Compile

When compiling a daily log:

1. Read `knowledge/index.md` first.
2. Read any existing pages that look relevant.
3. Prefer updating an existing page over creating a near-duplicate.
4. Create new concept pages only when the topic is truly distinct.
5. Create connection pages when a log reveals a cross-cutting insight.
6. Update `knowledge/index.md`.
7. Append a timestamped entry to `knowledge/log.md`.

### Query

When answering a question:

1. Read `knowledge/index.md` first.
2. Select the 3-10 most relevant pages.
3. Read those pages in full.
4. Answer with `[[wikilink]]` citations.
5. If asked to file the answer back, create a `knowledge/qa/` page, update `index.md`, and append to `log.md`.

### Lint

Check for:

1. Broken wikilinks
2. Orphan pages
3. Uncompiled daily logs
4. Stale compiled state
5. Missing backlinks
6. Sparse articles
7. Contradictions or stale guidance across articles

## Conventions

- Use Obsidian-style wikilinks without `.md`.
- Use lowercase hyphenated filenames.
- Write in factual, concise, encyclopedia style.
- Every wiki article must have YAML frontmatter.
- Every article must link back to its source daily log(s).
- `knowledge/index.md` is required and should stay compact enough to scan quickly.
- `knowledge/log.md` is append-only.

## OpenCode Integration

This repo includes a local OpenCode plugin in `.opencode/plugins/opencode-wiki.js`.

It does three things:

1. On `session.idle`, it captures the newly added portion of the conversation and queues `scripts/flush.py`.
2. Before compaction, it queues another flush so context is not lost.
3. It injects the current wiki index and recent daily-log context into the session system prompt.

The Python scripts use `opencode run` in headless mode with `OPENCODE_MEMORY_INTERNAL=1` so internal maintenance runs do not recursively trigger the plugin.
