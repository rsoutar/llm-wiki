# Contributing to llm-wiki

Thanks for your interest in **llm-wiki**! 🎉  
This project adapts Andrej Karpathy’s LLM Wiki pattern to OpenCode, turning your coding sessions into a self-improving, persistent knowledge base.

All types of contributions are welcome — bug reports, feature ideas, documentation fixes, code improvements, or even just sharing how you're using it in your own projects.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features or Improvements](#suggesting-features-or-improvements)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Project Structure](#project-structure)
- [Style Guidelines](#style-guidelines)
- [Questions?](#questions)

## Code of Conduct

We expect all contributors to be kind, respectful, and constructive. Harassment or offensive behavior of any kind will not be tolerated.

## Getting Started

1. Read the [README.md](README.md) to understand what the project does and how it works.
2. Check the open [Issues](https://github.com/rsoutar/llm-wiki/issues) and [Pull Requests](https://github.com/rsoutar/llm-wiki/pulls) to see what's being worked on.
3. If you're planning something substantial (new feature, architecture change, etc.), please open an issue first to discuss it — this helps avoid duplicated effort.

## Development Setup

```bash
# Clone the repo
git clone https://github.com/rsoutar/llm-wiki.git
cd llm-wiki

# Install Python dependencies
uv sync

# Install the OpenCode plugin dependencies
npm install --prefix .opencode

# Open the repository in OpenCode (important for testing the plugin)

```

You can now run the main scripts:

```bash
uv run python scripts/compile.py
uv run python scripts/query.py "Your test question here"
uv run python scripts/lint.py
```

**Tip:** When working on the wiki itself (e.g., improving the compiler), set the environment variable to avoid recursive capture:

```bash
OPENCODE_MEMORY_INTERNAL=1 uv run python scripts/compile.py
```

## How to Contribute

### Reporting Bugs

- Open an issue and use a clear, descriptive title.
- Describe the exact steps to reproduce the bug.
- Include:
  - OpenCode version (if known)
  - Operating system
  - Relevant logs (`flush.log`, `flush-errors.log`, or console output)
  - What you expected vs. what happened

### Suggesting Features or Improvements

Feature suggestions are very welcome, especially around:

- Better compilation quality
- Configurability (e.g., compile time, knowledge base structure)
- Support for other agents / editors
- Quality / linting improvements
- Documentation and examples

Please open an issue with:

- A clear description of the problem or idea
- Why it would be useful to users
- Any implementation ideas you already have

### Submitting Pull Requests

1. Fork the repository and create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes.
3. Ensure the code follows the existing style (see below).
4. Test your changes locally (run `lint.py`, `compile.py`, and `query.py` where relevant).
5. Commit with a clear, descriptive message.
6. Open a Pull Request against the `main` branch.

**Good PRs include:**

- A clear title and description of what was changed and why
- References to any related issues
- Updated documentation if behavior or usage changed
- Any new tests (if applicable)

## Project Structure

Key directories and files you'll likely touch:

- `.opencode/plugins/llm-wiki.js` — OpenCode plugin for capture & injection
- `scripts/` — Core Python tools (`flush.py`, `compile.py`, `query.py`, `lint.py`)
- `AGENTS.md` — Guidelines and schemas used by the compiler agents
- `knowledge/` and `daily/` — Generated (do **not** commit real content from your own projects; keep the repo clean)
- `opencode.json` — OpenCode configuration

See [README.md](README.md) for full layout and flow.

## Style Guidelines

- **Python**: Follow PEP 8. We use `uv` and `pyproject.toml` — run `uv run ruff check .` or `uv run ruff format .` if those tools are configured.
- **JavaScript**: Keep it simple and consistent with the existing plugin (no heavy frameworks).
- **Markdown**: Use clear, concise language. Prefer active voice.
- **Commit messages**: Use conventional style when possible (e.g. `feat:`, `fix:`, `docs:`, `refactor:`).

## Questions?

- Open an issue labeled `question`
- Or reach out via GitHub Discussions if we enable them later

Thank you again for contributing — every improvement helps make llm-wiki more useful for developers building long-term memory into their coding workflow!

Happy wiki-building! 🚀
