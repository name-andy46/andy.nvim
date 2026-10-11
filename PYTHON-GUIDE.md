# Writing Python in this config

Everything Python-specific this config does, and how to drive it.
Read it in nvim (`:e PYTHON-GUIDE.md`) — markview.nvim renders it.

Leader is `<Space>` throughout. See `C-GUIDE.md` for the C equivalent.

---

## The one rule: activate the venv first

```sh
source venv/bin/activate && nvim
```

**Every Python tool here — isort, black, flake8, debugpy — is resolved off `PATH`,
and nvim's `PATH` is fixed at the moment it launches.** Nothing in this config
detects or switches virtualenvs.

That is deliberate, and it is what makes the editor agree with your repo: the tools
that run are the ones your venv pins, which are the same ones `requirements/lint.txt`
pins for pre-commit. No second set of versions, nothing to drift.

What does **not** work:

- launching nvim first and activating a venv in a terminal split afterwards — that
  shell gets the new `PATH`, nvim's own process does not
- `:cd`-ing into a different repo mid-session — the venv stays whatever you started with

One repo per nvim session is the intended shape. If you need another, start another nvim.

> The terminal split (`<C-n>`) *does* auto-activate `./venv/bin/activate` when it exists
> (`lua/custom/plugins/toggle_term.lua`). That is for you, not for nvim — it does not
> affect the formatter or linter.

---

## Formatting on save

### The rule

**Python formats on save only when the project ships a `pyproject.toml`.**

Conform walks up from the file's directory looking for one, stopping just before
`$HOME`. Found it → run `isort` then `black`. Found none → the file is written
untouched. The same gate governs C, keyed on `.clang-format` instead.

| Where you are | On save |
| :- | :- |
| A repo with `pyproject.toml` | isort → black, using that repo's settings |
| A repo without one | **nothing happens** |
| A loose script anywhere | nothing happens |

Why: a repo that declares no style should not get yours. Formatting
`cloudv2_service_triggers` (no `pyproject.toml`) with another repo's black would
impose settings that repo never agreed to, and bury your real change in the diff.

### What actually runs

`isort` first, then `black` — sequentially, order enforced in `formatters_by_ft`.
That order matters and is not arbitrary: isort rearranges imports, black then
normalises the result. Reversed, black's output is no longer canonical and a second
run reports changes. Your `.pre-commit-config.yaml` says the same thing.

Both read the repo's own config. In `cloudv2_service_devices` that means
`[tool.black]` `line-length = 120`, `target_version = ['py313']`, and `[tool.isort]`
`profile = "black"` with its line-length override. Conform runs black with
`cwd` set to the directory holding `pyproject.toml`, so those settings are found.

### Formatting by hand

`<leader>f` always works, everywhere, and **skips the gate entirely**.

| Mode | What it formats |
| :- | :- |
| normal | the whole buffer |
| visual (select lines first) | only the selection |

Use the visual form in a repo that has no `pyproject.toml` but where you still want
your own new code tidy — it touches only what you selected.

---

## Linting

Two complementary things, both running the venv's `flake8` against the repo's own
`.flake8` config. Neither imposes rules of ours.

### Inline, as you work

`nvim-lint` runs flake8 on the current buffer on `BufEnter`, `BufWritePost` and
`InsertLeave`. Violations show as ordinary diagnostics, exactly like pyright's.

| Key | Does |
| :- | :- |
| `]d` / `[d` | next / previous diagnostic |
| `<leader>dq` | float the diagnostic under the cursor |
| `<leader>q` | all diagnostics in this buffer → location list |
| `<leader>sd` | search diagnostics (Telescope) |

Without an active venv this stays silent rather than erroring on every buffer.

**Expect noise on legacy files.** `cloudv2_service_devices` has a ~690-finding
baseline, so opening an untouched old file lights it up with problems that are not
yours. That is what the next section is for.

### Just what you are about to commit

`<leader>ls` — **[L]int [S]taged.** Runs flake8 over your staged `.py` files only
and loads the results into the quickfix list.

| Key | Does |
| :- | :- |
| `<leader>ls` | lint staged files → quickfix |
| `]q` / `[q` | next / previous entry |
| `:copen` / `:cclose` | open / close the list |

This is the same scope the pre-commit hook uses, so it answers "would my commit
pass?" without committing. Clean runs close the list and say so rather than
leaving an empty window.

If it reports `flake8 not on PATH` you forgot the venv.

---

## Navigating code

`pyright` attaches automatically. `:LspInfo` to confirm.

| Key | Does |
| :- | :- |
| `K` | hover docs |
| `grd` | goto definition |
| `grD` | goto declaration |
| `grr` | all references |
| `grn` | rename across files |
| `gra` | code action |
| `gO` | symbols in this file |
| `<C-s>` (insert) | signature help |
| `<leader>th` | toggle inlay hints |

Pyright is a **type checker**, not a linter and not a formatter. Type errors and
unresolved imports come from it; style violations come from flake8; formatting comes
from black. Three tools, three jobs, no overlap.

---

## Debugging

`nvim-dap` is wired for Python via `nvim-dap-python`, using `./venv/bin/python`
relative to nvim's working directory. Launching a file opens the dap-ui panels.

| Key | Does |
| :- | :- |
| `F5` | start / continue |
| `F1` | step into |
| `F2` | step over |
| `F3` | step out |
| `<leader>bdb` | toggle breakpoint |
| `<leader>bdB` | conditional breakpoint |
| `F7` | toggle the debug UI / last session result |

The configured launch runs the **current file** (`program = '${file}'`) with
`console = 'integratedTerminal'`. It needs `debugpy` in the venv.

---

## When something does not happen

| Symptom | Cause |
| :- | :- |
| Save does not format | no `pyproject.toml` above the file — by design |
| Save does not format, repo *has* `pyproject.toml` | venv not active; you may see "Formatters unavailable for python file" once |
| Imports not sorted, code formatted | `isort` missing from the venv; conform runs what it finds and skips the rest |
| No flake8 squiggles | venv not active, or the repo has no flake8 config |
| Squiggles everywhere on an old file | the pre-existing baseline — use `<leader>ls` for just your work |
| `<leader>ls` says flake8 not on PATH | venv not active |
| pre-commit rewrites files you already saved | a hook is doing something nvim does not run |

`:ConformInfo` lists the formatters for the buffer and whether each one resolved.
That is the fastest way to tell "gate blocked it" from "tool missing".

---

## Relationship to pre-commit

The hooks in `.pre-commit-config.yaml` use `language: system` — they run whatever
isort/black/flake8 are on `PATH` rather than building private copies. With the venv
active, **that is the same binary nvim uses.** Editor and commit hook cannot disagree.

Nvim runs three of the four hooks: isort, black, flake8. It does **not** run
`unittests` (`python -m pytest tests/unit -v`), so a commit can still fail on tests
that nvim never executed.

To run the hooks without committing:

```sh
pre-commit run                    # staged files (nothing staged = nothing runs)
pre-commit run --all-files        # whole repo
pre-commit run black --all-files  # one hook
```

On a fresh host clone, `pre-commit` itself may not be installed even though it is
pinned — it is installed into the devcontainer at image build time:

```sh
pip install -r requirements/lint.txt   # venv active
make pre-commit                        # installs .git/hooks/pre-commit
```

---

## Quick reference

| Want | Do |
| :- | :- |
| format on save | activate venv, work in a repo with `pyproject.toml` |
| format my selection | visual-select, `<leader>f` |
| format this file | `<leader>f` |
| check what would fail the hook | `<leader>ls` |
| walk the findings | `]q` |
| jump to a definition | `grd` |
| debug this file | `F5` |
| why isn't it formatting? | `:ConformInfo`, then check the venv |
