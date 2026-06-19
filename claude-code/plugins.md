# Claude Code Plugins

This file documents the Claude Code plugin setup observed on this machine.
It is generated from metadata in `~/.claude/settings.json`,
`~/.claude/plugins/known_marketplaces.json`, and
`~/.claude/plugins/installed_plugins.json`; it does not include plugin source.

The project-local `.claude/` folder currently contains only
`.claude/settings.local.json` with local command permissions. Installed plugins
are user-level Claude Code configuration, not project-local source files.

## Marketplace Setup

Add the marketplaces first:

```bash
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add florianbuetow/claude-code
claude plugin marketplace add https://github.com/josemlopez/claude-threatmodel.git
claude plugin marketplace add florianbuetow/claude-code-private
claude plugin marketplace add huggingface/skills
claude plugin marketplace add openai/codex-plugin-cc
claude plugin marketplace add JuliusBrussee/caveman
claude plugin marketplace add milla-jovovich/mempalace
claude plugin marketplace add hamelsmu/evals-skills
```

The private marketplace requires access to `florianbuetow/claude-code-private`.

Claude CLI syntax used here:

```bash
claude plugin marketplace add <source>
claude plugin install <plugin@marketplace>
claude plugin enable <plugin@marketplace>
```

## Installation Flow

On a new Mac, install Claude Code first, then run the commands in this order:

1. Add every marketplace from [Marketplace Setup](#marketplace-setup).
2. Install every plugin from [Enabled Plugins](#enabled-plugins).
3. Restart Claude Code so plugin commands, skills, hooks, MCP servers, and
   agents are reloaded.
4. Open Claude Code's `/plugin` UI to confirm the enabled/disabled state.
5. Install anything from [Installed But Disabled Or Omitted](#installed-but-disabled-or-omitted)
   only when you want that optional behavior.

For a plugin that is installed but not enabled after restart, run:

```bash
claude plugin enable <plugin@marketplace>
```

The CLI currently exposes `marketplace add`, `install`, `enable`, `disable`,
`uninstall`, and `validate`; use Claude Code's `/plugin` UI for an interactive
installed-plugin review.

## Enabled Plugins

Install and enable the plugins that are enabled in the current user config:

```bash
# claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install code-review@claude-plugins-official
claude plugin install code-simplifier@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install ralph-loop@claude-plugins-official
claude plugin install feature-dev@claude-plugins-official
claude plugin install pr-review-toolkit@claude-plugins-official
claude plugin install superpowers@claude-plugins-official
claude plugin install plugin-dev@claude-plugins-official
claude plugin install claude-md-management@claude-plugins-official
claude plugin install claude-code-setup@claude-plugins-official
claude plugin install huggingface-skills@claude-plugins-official
claude plugin install clangd-lsp@claude-plugins-official
claude plugin install swift-lsp@claude-plugins-official
claude plugin install jdtls-lsp@claude-plugins-official

# florianbuetow-plugins
claude plugin install beyond-solid-principles@florianbuetow-plugins
claude plugin install explain-system-tradeoffs@florianbuetow-plugins
claude plugin install solid-principles@florianbuetow-plugins
claude plugin install spec-writer@florianbuetow-plugins
claude plugin install spec-dd@florianbuetow-plugins
claude plugin install archibald@florianbuetow-plugins
claude plugin install kiss@florianbuetow-plugins
claude plugin install retrospective@florianbuetow-plugins
claude plugin install onboarding@florianbuetow-plugins
claude plugin install iso27001-sdlc@florianbuetow-plugins
claude plugin install logbook@florianbuetow-plugins
claude plugin install changelog@florianbuetow-plugins
claude plugin install agent-guardrails@florianbuetow-plugins
claude plugin install fixclaude@florianbuetow-plugins
claude plugin install sessionlog@florianbuetow-plugins
claude plugin install tokeneconomics@florianbuetow-plugins
claude plugin install context-research@florianbuetow-plugins
claude plugin install orchestrator@florianbuetow-plugins
claude plugin install progressive-disclosure@florianbuetow-plugins
claude plugin install handoff@florianbuetow-plugins
claude plugin install claudeignore@florianbuetow-plugins
claude plugin install guard@florianbuetow-plugins
claude plugin install terminator@florianbuetow-plugins

# josemlopez
claude plugin install threatmodel@josemlopez

# huggingface-skills
claude plugin install huggingface-papers@huggingface-skills

# openai-codex
claude plugin install codex@openai-codex

# hamelsmu-evals-skills
claude plugin install evals-skills@hamelsmu-evals-skills

# florianbuetow-plugins-private
claude plugin install knowledge-tree@florianbuetow-plugins-private
claude plugin install interview@florianbuetow-plugins-private
claude plugin install refine@florianbuetow-plugins-private
claude plugin install slashcommands@florianbuetow-plugins-private
claude plugin install delegate@florianbuetow-plugins-private
claude plugin install context@florianbuetow-plugins-private
claude plugin install nate@florianbuetow-plugins-private
claude plugin install bookreader@florianbuetow-plugins-private
claude plugin install l2org@florianbuetow-plugins-private
claude plugin install persona@florianbuetow-plugins-private
claude plugin install crackingaiengineering@florianbuetow-plugins-private
claude plugin install markdown-to-linkedin@florianbuetow-plugins-private
claude plugin install blog@florianbuetow-plugins-private
```

## Installed But Disabled Or Omitted

These plugins are installed locally but are disabled in `enabledPlugins`, or
present in install metadata without an enabled flag. Install them only if you
want the optional behavior:

```bash
claude plugin install github@claude-plugins-official
claude plugin install commit-commands@claude-plugins-official
claude plugin install explanatory-output-style@claude-plugins-official
claude plugin install learning-output-style@claude-plugins-official
claude plugin install appsec@florianbuetow-plugins
claude plugin install cache-money@florianbuetow-plugins
claude plugin install hookify@claude-plugins-official
claude plugin install caveman@caveman
```

## Notes

- `~/.claude/plugins/blocklist.json` contains local test blocklist entries; this
  bootstrap repo does not reproduce that blocklist.
- `~/.claude/plugins/cache/**` and `~/.claude/plugins/marketplaces/**` are
  plugin source/cache directories and should not be copied into this repository.
- `~/.claude/settings.local.json`, sessions, telemetry, plans, jobs, todos, and
  project caches are local state and are intentionally excluded.
