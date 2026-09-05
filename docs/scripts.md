# Scripts Reference

This document is the reference for the three maintenance scripts in `scripts/`: what each one does, which flags it accepts, and what it touches on the system. For step-by-step procedures (adding a package, adding a system file, resolving conflicts), see [`docs/managing.md`](managing.md).

All three scripts share the same conventions:

- Colored, timestamped terminal output (`[ OK ]`, `[WARN]`, `[ERR ]`, `[INFO]`)
- A log file written to `logs/<script>/<script>_<timestamp>.log` on every run. Logs are auto-rotated on each run via the shared `rotate_logs()` helper in `scripts/lib/common.sh`: entries older than 30 days are pruned, always keeping at least the 10 most recent regardless of age. A log that can't be deleted (e.g. owned by `root` from a `sudo` run) is reported as `[WARN]` rather than aborting the run.
- `command find`, `command grep`, etc. used internally where relevant, so behavior doesn't change if `find`/`grep` are aliased to other tools (e.g. `fd`, `ripgrep`) in your interactive shell
- `--help` / `-h` to print usage and exit

---

## Quick reference

| Script         | Purpose                                       | Flags                                                                                                                                                                                                             | Needs sudo                                | Stops on running system?  |
| -------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | ------------------------- |
| `install.sh`   | Deploy the repo onto a system                 | `--packages-only` `--symlinks-only` `--root-bashrc-only` `--link-scripts-only` `--fonts-only` `--system-only` `--unstow-only` `--dry-run` (the `*-only` flags are combinable, except `--unstow-only` — see below) | Yes (packages, root bashrc, system files) | No — writes/changes files |
| `status.status | Pull the running system's state into the repo | `--packages-only` `--system-only` `--versions-only`                                                                                                                                                               | Yes (system files)                        | No — writes into the repo |
| `status.sh`    | Read-only health-check, no writes             | none required; optionally pass binary names to override step 3                                                                                                                                                    | No                                        | No — diagnostic only      |

Run any script with no flags for its full behavior; each flag narrows it to a single phase.

---

## install.sh

Deploys the repo onto a system: installs packages, creates Stow symlinks, installs system-level files, and a few smaller housekeeping steps.

```bash
./scripts/install.sh                        # full installation
./scripts/install.sh --packages-only         # install packages only
./scripts/install.sh --symlinks-only         # create symlinks only
./scripts/install.sh --root-bashrc-only      # copy configs/bash/.bashrc to /root/.bashrc only
./scripts/install.sh --link-scripts-only     # link scripts/*.sh into ~/.local/bin only
./scripts/install.sh --fonts-only            # refresh the font cache only
./scripts/install.sh --system-only           # install /etc and /usr files only (needs sudo)
./scripts/install.sh --unstow-only           # remove all Stow symlinks (undo, repo files untouched)
./scripts/install.sh --dry-run               # preview every command without applying it
```

> Each `*-only` flag runs exactly one step. Combine them freely, e.g. `./install.sh --symlinks-only --fonts-only`. With no flags, every step runs.

### What each phase does

**Packages** (`install_packages`) — runs `pacman -Syu`, installs everything listed in `packages/packages.txt` via `pacman`, then installs everything in `packages/aur-packages.txt` via an AUR helper. If no AUR helper (`yay` or `paru`) is found, `install.sh` builds and installs `yay` from source automatically. Packages listed in `NON_BLOCKING_AUR` (currently just `spicetify-cli`) are allowed to fail without stopping the script — everything else aborts the run on failure.

**Stow** (`stow_packages`) — stows every directory under `configs/` (package list is auto-discovered, nothing to register manually). Before stowing a package, any real file that would conflict with the incoming symlink is moved to `~/.dotfiles-backup/<timestamp>/<package>/<relative path>`, unless that file already resolves inside the repo itself (in which case it's left alone, since it's Stow's own symlink target). This backup step is separate from the manual `.bak` convention described in `managing.md` — it's automatic and only triggers on a real Stow conflict.

**Unstow** (`unstow_packages`) — the inverse of the Stow phase: removes the Stow symlinks for every package under `configs/`, leaving the repo files themselves untouched. Only runs via the explicit `--unstow-only` flag, never as part of a full install — it's an opt-in undo, not a step in the normal deploy sequence. Don't combine it with `--symlinks-only` in the same run; the two are contradictory (one stows, the other immediately un-stows).

**Root bashrc** (`install_root_bashrc`) — copies `configs/bash/.bashrc` to `/root/.bashrc` (root can't use a symlink into a regular user's home). Any existing `/root/.bashrc` is backed up first as `/root/.bashrc.bak.<timestamp>`. See [`docs/managing.md`](managing.md#bash-user--root) for why root needs a separate copy.

**System files** (`install_system_files`) — reads `scripts/system-files.conf` and copies each repo file to its real destination, backing up the existing destination file as `<dest>.bak` first (directories are copied recursively without a backup step).

**Personal scripts** (`install_scripts`) — makes every `scripts/*.sh` executable and symlinks it into `~/.local/bin/<name>` (without the `.sh` extension). This means `status.sh` becomes runnable as `status` from anywhere once `~/.local/bin` is in `PATH`.

**Font cache** (`refresh_fonts`) — runs `fc-cache -fv`.

### Logging

Every run writes to `logs/install/install_<timestamp>.log`, with automatic rotation as described above. In `--dry-run` mode, commands are printed instead of executed and nothing is applied. Check the log after any run that reported warnings or errors.

---

## sync.sh

Pulls the running system's state back into the repo: refreshes package lists, copies system files from their real location into `system/`, and updates the component version table in `README.md`. Since Stow packages are symlinked, editing a config file already edits the repo directly — `sync.sh` has nothing to do with `configs/`.

```bash
./scripts/sync.sh                  # full sync: packages + system files + versions
./scripts/sync.sh --packages-only  # only regenerate packages/*.txt
./scripts/sync.sh --system-only    # only copy system files into the repo
./scripts/sync.sh --versions-only  # only update the version table in README.md
```

### What each phase does

**Packages** (`sync_packages`) — regenerates `packages/packages.txt` from `pacman -Qqen` (explicitly installed, non-dependency packages) and `packages/aur-packages.txt` from `pacman -Qqem` (foreign/AUR packages), excluding the AUR helper itself (`yay`, `yay-bin`, `paru`, `paru-bin`) so the bootstrap tool doesn't get committed as a tracked package.

**System files** (`sync_system_files`) — reads `scripts/system-files.conf` and copies each real system file back into its repo location (the reverse direction of `install.sh`'s system files step). Unlike `install.sh`, this direction does not create a `.bak` of the repo copy before overwriting it — the repo file is expected to be tracked by git, so its history is the backup.

**Versions** (`update_versions`) — reads the currently installed versions of Kernel, Hyprland, Hyprlock, Waybar, Kitty, Rofi, and Dunst directly from each tool's own version output, then rewrites the matching rows in the `## Versions` table in `README.md` via `sed`. Any tool that can't be detected (not installed, unexpected version string) is skipped with a warning — its row in the README is left untouched rather than blanked.

### Logging

Every run writes to `logs/sync/sync_<timestamp>.log`, with automatic rotation as described above.

---

## status.sh

Read-only health-check. Makes no changes to the system or the repo — safe to run at any time, including as a habit after `install.sh`/`sync.sh`, after a system update, or whenever something feels off.

```bash
./scripts/status.sh                    # run all four checks
./scripts/status.sh go stow hyprctl    # run all checks, override the binaries list for check 3
```

### What it checks

1. **Stow symlink integrity** — walks `$HOME` for symlinks pointing into `configs/`, flags any that are broken, and flags any Stow package with no active symlink anywhere (never stowed, or unstowed by mistake). Unrelated symlinks from third-party apps (lock files, caches — e.g. Discord, Obsidian, Spotify, Firefox) are ignored by default; see `IGNORED_SYMLINK_DIRS` in the script to extend the list. Broken symlinks found inside `.bak`/legacy backup folders are reported separately as low-priority leftovers, since they don't affect the running system.
2. **System file alignment** — reads `scripts/system-files.conf` (the same file `install.sh` and `sync.sh` use) and diffs each repo file against its real counterpart, reporting anything out of sync or missing in either direction.
3. **Critical binaries in `PATH`** — confirms core tools (`stow`, `hyprctl`, `waybar`, `rofi`, `dunst`, `clipse`, etc. — see `DEFAULT_CRITICAL_BINS` in the script) are reachable. Override the list by passing binary names as arguments.

   **What this check is for:** the Stow symlink check (check 1) only verifies that a package's _config files_ are correctly linked — it says nothing about whether the underlying _program_ is actually installed and reachable. A package can be perfectly stowed while its binary is missing (e.g. removed by an interrupted AUR build, a broken package, or a `go install` that was never re-run after a Go upgrade), silently breaking the feature at runtime with no warning from the rest of the health-check. This check exists to catch exactly that gap.

   **Not auto-discovered:** unlike checks 1, 2 and 4, this list is a plain hardcoded array in the script (`DEFAULT_CRITICAL_BINS`), not derived from `configs/`. Adding a package that wraps its own executable doesn't automatically get its binary checked.

   Skipping this doesn't break anything immediately — it just means `status.sh` won't be able to catch that specific failure mode later, which defeats part of its purpose as an early-warning tool. See [`docs/managing.md`](managing.md#adding-a-new-package) for the checklist on when a new package needs this.

4. **Stale absolute paths in `configs/`** — scans tracked config files for absolute paths that mention `dotfiles` as a path segment but don't match the repo's current location. Catches leftovers from a repo path migration (e.g. a config file still hardcoding an old path after the repo moved) without flagging unrelated absolute paths (wallpapers, other apps' config dirs, `~/Documents`-style bookmarks, etc.), which are expected and not stale.

### Exit code and logging

Exits `0` if every check passed, `1` if any `[WARN]`/`[ERR ]` was reported — safe to wire into a periodic check or a pre-commit hook. Every run writes to `logs/status/status_<timestamp>.log`, with automatic rotation as described above.

Unlike the other two scripts, `status.sh` does not use `set -e`: it's diagnostic, so a failed check should be reported and the script should keep running the remaining checks rather than abort on the first problem.
