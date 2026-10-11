# Writing C in this config

Everything C-specific this config does, and how to drive it.
Read it in nvim (`:e C-GUIDE.md`) — markview.nvim renders it.

Leader is `<Space>` throughout. See `PYTHON-GUIDE.md` for the Python equivalent.

---

## Formatting

### The rule

**C formats on save only when the project ships its own `.clang-format`.**

This is one half of a general rule — Python works the same way, keyed on
`pyproject.toml` instead. See `PYTHON-GUIDE.md`.

On save, conform walks up from the file's directory looking for a `.clang-format`,
stopping *just before* `$HOME`. Found one → format. Found none → the file is written
untouched.

`~/.clang-format` exists and holds the house style, but it lives at `$HOME`, so the
upward walk never reaches it. It is deliberately **not** a declaration — it is only the
style that manual formatting falls back on.

| Where you are | On save |
| :- | :- |
| A project with its own `.clang-format` | formats, using that file |
| A project without one (e.g. `icastsense_fw_apollo`) | **nothing happens** |
| Lua / Python | unaffected — stylua and black always run |

Why: the firmware repo declares no style and is internally inconsistent (8520
tab-indented lines against 15381 space-indented). Reformatting on save there rewrites
25–50% of a file, burying your one-line change. See `notes/nvim-c-setup-for-firmware.md`.

### Formatting by hand

`<leader>f` always works, everywhere, regardless of the rule above.

| Mode | What it formats |
| :- | :- |
| normal | the whole buffer |
| visual (select lines first) | **only the selection** |

**In the firmware repo, use the visual-mode form.** Select the lines you added, `<leader>f`,
done — the rest of the file stays as it was. This is the whole point of the save rule: you
opt in per-edit instead of rewriting files you didn't author.

### Turning save-formatting on for a new project

Drop a `.clang-format` at the project root. Simplest is to copy the house style:

```sh
cp ~/.clang-format /path/to/project/.clang-format
```

That one file is the entire opt-in. Everything under that directory now formats on save.

**If save-formatting isn't happening in a new C directory, this is why.** It's the one
non-obvious part of the setup.

### The house style

`~/.clang-format` was derived by measuring the firmware repo, so code you write matches
what you'll read there: **Allman braces** (brace on its own line), 4-space indent, never
tabs, `if (x)` with the space, indented `case` labels, 100-column limit.

Two deliberate choices: `SortIncludes: Never`, because firmware headers are order-dependent
and resorting them breaks builds in ways that are miserable to trace; and
`ReflowComments: false`, to leave hand-drawn `//****` banner blocks alone.

To override it for one project, edit that project's own `.clang-format` — it wins, being
nearer the file.

---

## Build and run

`:make` builds, and errors land in the quickfix list. What it runs depends on the directory:

- a `Makefile` (or `makefile`) is present → runs `make`
- no Makefile → runs `gcc -std=c11 -Wall -Wextra -g -o <name> <file>`

So single-file exercises just work, and the moment you write a Makefile, `:make` switches
to it with no config change.

`-Wall -Wextra` is on deliberately: those warnings catch the mistakes worth learning from.
`-g` means the binary is already debuggable.

| Command | Does |
| :- | :- |
| `:make` | build; jumps to the first error |
| `:copen` / `:cclose` | open / close the quickfix list |
| `:cnext` / `:cprev` | next / previous error |
| `:cfirst` | back to the first error |
| `:!./%:r` | run the binary built from this file |

Write the Makefiles by hand. The firmware repo is ~40 hand-written recursive Makefiles and
no CMake, so reading make is a prerequisite there, not optional side knowledge.

---

## Navigating code (clangd)

clangd attaches to C buffers automatically. `:LspInfo` to confirm, `:ConformInfo` for
formatter status.

| Key | Does |
| :- | :- |
| `K` | hover docs for the symbol under the cursor |
| `grd` | goto definition |
| `grD` | goto **declaration** — in C, the header |
| `grr` | all references |
| `grn` | rename across files |
| `gra` | code action (on an error or suggestion) |
| `gO` | symbols in this file |
| `<C-s>` (insert) | signature help — argument list while typing a call |
| `<leader>q` | all diagnostics → location list |
| `<leader>dq` | float the diagnostic under the cursor |
| `<leader>sd` | search diagnostics (Telescope) |
| `<leader>th` | toggle inlay hints |

Standalone `.c` files make clangd warn that it can't find a compilation database. It still
works on defaults — it's noise, not breakage. If it gets loud on a multi-file chapter, add
`compile_flags.txt` next to the sources, one flag per line:

```
-std=c11
-Wall
```

---

## Debugging

`gdb` is installed and used from a terminal — deliberately, rather than through nvim-dap.
It's what every C book and answer online assumes, and it transfers.

`<C-n>` toggles a terminal split. `:make` already builds with `-g`, so:

```sh
gdb ./your_program
```

| gdb | Does |
| :- | :- |
| `break main` / `b file.c:42` | set a breakpoint |
| `run` | start |
| `next` / `step` | over / into |
| `print x` / `p *ptr` | inspect a value |
| `backtrace` | how you got here |
| `continue` | resume |
| `quit` | exit |

---

## Quick reference

| Want | Do |
| :- | :- |
| format my selection | visual-select, `<leader>f` |
| format this file | `<leader>f` in normal mode |
| turn on save-formatting here | `cp ~/.clang-format .` |
| build | `:make` |
| walk the errors | `:copen`, then `:cnext` |
| run it | `:!./%:r` |
| why isn't it formatting? | no `.clang-format` in the project — by design |
