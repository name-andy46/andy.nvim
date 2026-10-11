# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal Neovim configuration forked from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
(origin: `name-andy46/andy.nvim`, upstream kickstart merged in periodically on `andy-dev`).
It lives at `~/.config/nvim`, so editing files here changes the editor immediately — there is no build step.
`README.md` and `doc/kickstart.txt` are upstream kickstart documentation, not documentation of this fork.
`C-GUIDE.md` and `PYTHON-GUIDE.md` **are** local: the per-language workflows (the shared
format-on-save gate, build/lint commands, LSP keymaps, debugging) — read the relevant one before
answering anything about writing C or Python here.

## Commands

```sh
stylua --check .        # lint/format check — the only CI gate (.github/workflows/stylua.yml)
stylua .                # apply formatting (.stylua.toml: 160 cols, 2-space, single quotes,
                        #   no call parens, collapse_simple_statement = Always)
nvim --headless "+Lazy! sync" +qa   # install/update plugins non-interactively
```

Inside Neovim: `:Lazy` (plugin status), `:Mason` (tool installs, host only), `:ConformInfo`
(formatter status), `:checkhealth kickstart` (validates external deps — see `lua/kickstart/health.lua`).

There are no tests. "Testing a change" means restarting `nvim` (or `<leader><leader>x` to source the
current file) and watching for errors from `:Lazy`/`:messages`.

## Architecture

**Everything material is in `init.lua` (~1000 lines).** It is a single kickstart-style file: options
and keymaps first, then one `require('lazy').setup({...})` call containing every core plugin spec inline.
Do not split it up — matching kickstart's shape keeps upstream merges tractable. New *plugins* go in
`lua/custom/plugins/<name>.lua` (one file returning a lazy spec; auto-loaded via
`{ import = 'custom.plugins' }` at the end of the setup table). New *options/keymaps* go in `init.lua`.

`lua/kickstart/plugins/*` are upstream's optional modules, opted in individually near the bottom of
`init.lua` (`debug`, `autopairs`, `neo-tree`, `gitsigns` are on; `indent_line` and `lint` are commented out).
Treat these as upstream files — prefer minimal local edits so merges stay clean.

### The `DEVCONTAINER` split — the one non-obvious thing

`vim.env.DEVCONTAINER` gates six places in `init.lua`, because inside the devcontainer GitHub is blocked
by the firewall and plugins arrive via a bind mount:

| Concern | Host | `DEVCONTAINER` set |
| :- | :- | :- |
| LSP install (`lspconfig` deps, ~line 551) | Mason + mason-lspconfig + mason-tool-installer | fidget + blink only; LSPs assumed preinstalled |
| `mason-tool-installer` / `lua_ls` config (~695, ~713) | configured | skipped entirely |
| Colorscheme (~899) | `tokyonight-night` | builtin `retrobox` |
| Treesitter (~954) | `require('nvim-treesitter').install(...)` | prepend bundled `runtime/` to rtp instead |
| lazy.nvim `git` / `checker` / `change_detection` (~1017) | default | all disabled |

Any new plugin that downloads a binary, clones a repo, or depends on Mason needs the same guard.

### Key conventions

- Leader and localleader are both `<Space>`. Keymaps use kickstart's `[B]racketed letter` desc style —
  which-key renders those descriptions, so always pass `{ desc = ... }`.
- `vim.g.have_nerd_font = false` — icon tables throughout fall back to unicode. Don't assume a Nerd Font.
- LSP servers are declared in the `servers` table (~line 692) and enabled with `vim.lsp.config` /
  `vim.lsp.enable` (new-style API, not `lspconfig.setup`). Currently `pyright` and `clangd`, plus
  host-only `lua_ls`. Mason's `ensure_installed` is derived from this table, so adding a key installs it.
- Formatting is conform.nvim with format-on-save (`lua = stylua`, `python = isort` then `black`,
  `c = clang-format`; `cpp` disabled). **C and Python are gated** by the `style_marker` table in
  `format_on_save`: they only format when the project declares a style — `.clang-format` for C,
  `pyproject.toml` for Python — found by an upward search stopping before `$HOME`, so a marker in
  `$HOME` doesn't count. Repos declaring no style (the firmware repo; `cloudv2_service_triggers`) are
  left alone on save; `<leader>f` still formats a visual selection. Don't "fix" this by removing the
  gate; see `C-GUIDE.md` / `PYTHON-GUIDE.md`.
- Python tooling (isort/black/flake8/debugpy) resolves off `PATH`, i.e. from the venv active when nvim
  launched — deliberately, so it matches what the repo pins for pre-commit. Nothing auto-detects venvs.
- Linting is nvim-lint (`lua/kickstart/plugins/lint.lua`, enabled): `python = { 'flake8' }`, guarded to
  stay silent when the binary isn't on `PATH`. `<leader>ls` lints staged files into quickfix.
- `lazy-lock.json` is committed **despite being listed in `.gitignore`** (inherited from upstream) — it is
  tracked, so plugin updates produce a lock diff that should be committed with them.
