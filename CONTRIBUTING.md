# Contributing Guidelines

## Commit Message Format

This document defines the commit message convention used in this repository. It's loosely inspired by [Angular's convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md), adapted to fit a personal, single-maintainer dotfiles repo rather than a large multi-contributor project.

Each commit message consists of a **header** (mandatory), and an optional **body** and **footer**.

```
<header>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Commit Message Header

```
<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary: imperative, present tense, no leading capital, no trailing dot
  │       │
  │       └─⫸ Scope (optional): see below
  │
  └─⫸ Type: CHORE|DOCS|FEAT|FIX|OTHER|PERF|REFACTOR|STYLE|TEST
```

- `<type>` and `<summary>` are mandatory.
- `<scope>`, if present, has **no space** before the parenthesis: `FEAT(hypr): ...`, not `FEAT (hypr): ...`.
- No blank line is needed after the header for single-line commits — body and footer are optional, add them only when they earn their place (see below).

#### Type

| Type         | Meaning                                                                                   |
| :----------- | :---------------------------------------------------------------------------------------- |
| **CHORE**    | Changes to tooling, scripts, or repo housekeeping that aren't a feature or a fix          |
| **DOCS**     | Documentation only changes (`docs/`, `README.md`, `CONTRIBUTING.md`)                      |
| **FEAT**     | A new capability — a new Stow package, a new script flag, a new keybinding                |
| **FIX**      | A bug fix — broken symlink logic, a wrong path, a script that fails silently              |
| **OTHER**    | Anything that doesn't fit the above — should be rare                                      |
| **PERF**     | A change that improves performance (e.g. Waybar refresh interval, script execution time)  |
| **REFACTOR** | A change that neither fixes a bug nor adds a feature (e.g. restructuring a script's flow) |
| **STYLE**    | Changes that don't affect behavior — formatting, whitespace, CSS/theming tweaks           |
| **TEST**     | Adding or correcting `status.sh` checks or other verification logic                       |

#### Scope

Scope is **optional**. Use it when a commit is localized to one area of the repo; omit it when the change is cross-cutting (e.g. touches multiple Stow packages, or the repo's structure as a whole).

There's no fixed, enumerated list of scopes to memorize. The rule is simple:

> **The scope is the name of the directory the commit touches.**

For a Stow package, that's the package name under `configs/` — same name `managing.md` uses when you add a new package, so it stays in sync automatically without a separate list to update.

| Area touched                      | Scope                                                                    |
| --------------------------------- | ------------------------------------------------------------------------ |
| `configs/<pkg>/`                  | `<pkg>` (e.g. `hypr`, `waybar`, `dunst`, `kitty`, `rofi`, `clipse`, ...) |
| `scripts/` (any of the 3 scripts) | `scripts`                                                                |
| `docs/`                           | `docs`                                                                   |
| `packages/`                       | `packages`                                                               |
| `system/` (any subfolder)         | `system`                                                                 |
| Root-level / spans multiple areas | _(omit scope)_                                                           |

#### Summary

- Imperative, present tense: `add`, not `added` or `adds`.
- No capital letter at the start.
- No period at the end.

### Commit Message Body

Optional for every type — use it when the summary alone doesn't explain _why_ the change was made, not as a mandatory ritual for every commit. A one-line fix to a rounding value doesn't need a body; a change that alters behavior in a non-obvious way (e.g. why `status.sh` checks a symlink a certain way) usually does.

When present, same imperative present-tense style as the summary. Explain the motivation — the _why_, not a restatement of the diff.

### Commit Message Footer

Optional. Used for breaking changes, deprecations, or references to issues/PRs.

```
BREAKING CHANGE: <summary>
<BLANK LINE>
<description + migration instructions>
```

or

```
DEPRECATED: <what's deprecated>
<BLANK LINE>
<description + recommended replacement>
```

---

### Examples

```
FEAT(clipse): add manual Go build fallback for broken AUR package
FIX(scripts): protect grep with `command` in check_system_alignment
DOCS: add commit message convention
CHORE(scripts): expose unstow_packages via --unstow-only flag
STYLE(waybar): adjust button opacity on hover
REFACTOR: split critical binaries check into a dedicated function
```

> **Note:** this convention applies going forward — existing commit history predates it and won't be rewritten.
