# Managing Configurations

This document explains how to add, remove, and maintain configurations tracked in this repo.

Configurations are managed in two different ways depending on where they live on the system. User-space configs (under `$HOME`) are handled with **GNU Stow**, which creates symlinks so that any edit is immediately reflected in the repo. System-level files (under `/etc` or `/usr/share`) require root access and cannot be symlinked, so they are managed via **install/sync scripts** that copy files in both directions.

This document covers procedures — how to add, remove, and fix things. For what each script actually does under the hood (flags, phases, logging), see [`docs/scripts.md`](scripts.md).

## Contents

- [Stow packages](#stow-packages)
  - [The stow command](#the-stow-command)
  - [Tree folding (`--no-folding`)](#tree-folding---no-folding)
  - [Adding a new package](#adding-a-new-package)
  - [Bash (user + root)](#bash-user--root)
  - [Resolving conflicts](#resolving-conflicts)
  - [Removing a package](#removing-a-package)
- [System files](#system-files)
  - [Adding a new system file](#adding-a-new-system-file)
- [Edit workflow](#edit-workflow)
- [Checking system health](#checking-system-health)
- [After any change](#after-any-change)

---

## Stow packages

### The stow command

Every Stow operation in this repo uses the same base command — only the package name and an optional flag change:

```bash
stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> <package>
```

`--no-folding` is what `install.sh` passes too — see [Tree folding](#tree-folding---no-folding) below for why it matters.

> **Note:** Stow does not expand the tilde (`~`) in `--dir` and `--target`. Always use the full absolute path as above, not `~`.

- **Stow a package:** `... <package>`
- **Remove a package's symlinks (without touching the repo):** add `-D` → `... -D <package>` (`--no-folding` is not needed for this)
- **Re-stow after moving/renaming files inside a package:** add `-R` → `... -R <package>`

The sections below use a shortened `stow ... <package>` for brevity — substitute the full command above.

> **Automation note:** `install.sh` automatically detects any directory placed inside `configs/` — you don't need to register package names anywhere. Create the folder, populate it, and run `./scripts/install.sh --symlinks-only`.

### Tree folding (`--no-folding`)

By default Stow _folds_: if the target directory doesn't exist yet, it creates **one symlink for the whole directory** (`~/.config/clipse` → `configs/clipse/.config/clipse`) instead of one symlink per file. If the directory already exists as a real directory, it links the files one by one. So the result depends on what happened first on that machine — and with a folded link, everything the app writes later ends up **inside the repo**.

Real example: clipse stores its clipboard history (`clipboard_history.json`), `clipse.log` and copied images (`tmp_files/`) next to its config. On a machine where clipse had already run before the first stow, only `config.json` and `custom_theme.json` were linked and the runtime data stayed outside the repo. On a freshly installed machine the directory didn't exist, Stow folded it, and every copied password and screenshot started showing up as untracked files in `git status`.

This repo therefore **always stows with `--no-folding`** (`install.sh` does it automatically): Stow creates real directories and links only the files that are in the repo, so the outcome no longer depends on install order.

Consequences worth knowing:

- **Files created directly under `~/.config/<package>/` are not in the repo** — only files that exist under `configs/<package>/` are linked. To track a new file, create it inside the repo (`configs/<package>/.config/<package>/...`) and run `./scripts/install.sh --symlinks-only` to link it.
- **A package that is already folded stays folded**: Stow considers the existing directory symlink correct and leaves it alone. To convert it (clipse as an example), unstow, move the runtime data out of the repo, and stow again:

  ```bash
  # 1. Remove the folded directory symlink (repo files are untouched)
  stow --dir=/home/<user>/.dotfiles/configs --target=/home/<user> -D clipse

  # 2. Recreate the real directory and move the runtime data into it
  #    (adjust the list to what actually exists; check `git status` afterwards)
  mkdir -p ~/.config/clipse
  mv ~/.dotfiles/configs/clipse/.config/clipse/{clipboard_history.json,clipse.log,tmp_files} ~/.config/clipse/

  # 3. Stow again, file by file
  stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> clipse
  ```

- **How to check which situation you're in:** `ls -ld ~/.config/clipse` should show a real directory (`drwx…`), and `ls -l ~/.config/clipse` should show symlinks only for the files that live in the repo. A `lrwx…` on the directory itself means it is folded.

### Adding a new package

```bash
# 1. Create the stow package structure inside configs/
mkdir -p ~/.dotfiles/configs/<new_package>/.config/<new_package>

# 2. Move the existing config from the system into the repo
mv ~/.config/<new_package> ~/.dotfiles/configs/<new_package>/.config/

# 3. Create the symlinks with stow (--no-folding: link files, not the whole directory)
stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> <new_package>

# 4. Verify: the directory is real, the files inside are symlinks into the repo
ls -ld ~/.config/<new_package>      # expected: a real directory (drwx...)
ls -l  ~/.config/<new_package>      # expected: <file> -> /home/<user>/.dotfiles/configs/<new_package>/.config/<new_package>/<file>
```

> Note: with `--no-folding` the _directory_ is not a symlink — each file in it is. If you ever see `~/.config/<new_package>` itself as a symlink (`lrwx...`), the package is folded: see [Tree folding](#tree-folding---no-folding).

#### Step 5 (conditional): register a critical binary

Does this package need a check 3 entry in `status.sh`? See [`docs/scripts.md`](scripts.md#statussh) for what a "critical binary" is and why it matters. Quick criteria to decide:

- Does the package wrap an actual **executable/daemon**, not just passive config, styling, or assets? (`hypr`, `waybar`, `dunst`, `clipse` → yes; `fonts`, `fontconfig`, `gtk`, `face` → no, nothing to check)
- Is that executable invoked **automatically** by something else (an `hl.exec_cmd(...)` call inside the `hl.on("hyprland.start", ...)` autostart block in `hyprland.lua`, a keybind, a systemd/user service) — i.e. would you _not_ immediately notice if it silently failed to launch?
- Is it installed through a **fragile path** (manual build, Go/Cargo/pip install, an AUR package with a history of broken builds) rather than a stable official-repo package?

```bash
# 5. If yes to the first two, add the binary name to `DEFAULT_CRITICAL_BINS` in `scripts/status.sh`:
DEFAULT_CRITICAL_BINS=(go stow hyprctl hyprpaper hyprlock waybar rofi kitty dunst clipse <new_binary>)
# then run `./scripts/status.sh` to confirm it shows up under "Checking critical binaries in PATH"
```

For files that live directly in `$HOME` (like `.bashrc`):

```bash
mkdir -p ~/.dotfiles/configs/<new_package>
mv ~/.<new_package>rc ~/.dotfiles/configs/<new_package>/.<new_package>rc
stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> <new_package>
```

### Bash (user + root)

Bash is a Stow package like any other for the current user (`configs/bash/.bashrc` → `~/.bashrc`), but with one exception: **root also needs a copy**, and root's home (`/root`) can't use a symlink into a regular user's home directory. So `install.sh` copies — not symlinks — `configs/bash/.bashrc` to `/root/.bashrc` as a separate step, right after stowing.

Practical implication: editing `configs/bash/.bashrc` updates `~/.bashrc` immediately (it's a symlink), but **`/root/.bashrc` stays stale until you re-run the copy step**:

```bash
cd ~/.dotfiles
./scripts/install.sh --symlinks-only --root-bashrc-only   # re-stows configs/ AND refreshes /root/.bashrc
```

Or copy it manually without touching anything else:

```bash
sudo cp configs/bash/.bashrc /root/.bashrc
```

See [`docs/scripts.md`](scripts.md) for the full list of `install.sh` flags.

Root also gets its own separate bash history (`/root/.bash_history`) rather than sharing the user's `~/.local/share/bash/history` (XDG_DATA_HOME) — this avoids permission issues between the two accounts.

### Resolving conflicts

Stow refuses to create a symlink if the target already exists as a real file. This happens when the application was used before being added to the repo. The fix is to remove the real file first, then stow:

```bash
# Back up the existing file if needed
mv ~/.config/<new_package> ~/.config/<new_package>.bak

# Then stow normally
stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> <new_package>
```

### Removing a package

To remove symlinks without deleting files from the repo:

```bash
stow --dir=/home/<user>/.dotfiles/configs --target=/home/<user> -D <new_package>
```

To remove **all** packages' symlinks at once (e.g. before migrating to a new machine, or to fully undo a `--symlinks-only` run) rather than one at a time, use `install.sh`'s dedicated flag instead of looping the command above manually:

```bash
./scripts/install.sh --unstow-only
```

This iterates over every package in `configs/` and runs `stow -D` on each — repo files are untouched either way, only the symlinks in `$HOME` are removed. See [`docs/scripts.md`](scripts.md#installsh) for details.

---

## System files

### Adding a new system file

System files are tracked in `scripts/system-files.conf` — both `install.sh` and `sync.sh` read from it automatically.

```bash
# 1. Create the folder structure inside system/
mkdir -p ~/.dotfiles/system/<new_entry>/

# 2. Copy the file from the system into the repo
sudo cp /etc/<new_file>.conf ~/.dotfiles/system/<new_entry>/
sudo chown $USER:$USER ~/.dotfiles/system/<new_entry>/<new_file>.conf

# 3. Add the mapping to scripts/system-files.conf
echo "system/<new_entry>/<new_file>.conf:/etc/<new_file>.conf" >> ~/.dotfiles/scripts/system-files.conf
```

From now on:

- `./sync.sh --system-only` will copy the file from the system back into the repo
- `./install.sh --system-only` will deploy it from the repo to the system

---

## Edit workflow

The two management approaches have opposite edit flows — it is important not to confuse them:

**Stow packages (`configs/`)** — symlinked to `$HOME`, so editing the file on the system and editing the file in the repo are the same operation. No sync needed.

```
Edit ~/.config/hypr/hyprland.lua → already reflected in the repo → git commit
```

> **Note:** this holds for files that already exist in the repo. A brand-new file created under `~/.config/<package>/` is a real file outside the repo (see [Tree folding](#tree-folding---no-folding)) — create it in `configs/<package>/...` and run `./scripts/install.sh --symlinks-only` instead.

> **Note:** since the Lua migration, `hyprland.lua` is the file Hyprland actually loads.

**System files (`system/`)** — copied, not symlinked. Always edit the real file on the system, then pull it into the repo with the sync script. Editing directly in `system/` repo folder has no effect on the running system and will be overwritten on the next sync.

```
Edit /etc/sddm.conf → ./scripts/sync.sh --system-only → git commit
```

---

## Checking system health

Run `./scripts/status.sh` any time after making changes, after a system update, or when something feels off — it's a read-only diagnostic that checks Stow symlink integrity, system file alignment, critical binaries, and stale paths from past migrations. See [`docs/scripts.md`](scripts.md) for the full breakdown of what it checks.

---

## After any change

Whether you added a Stow package or a system file, always close the loop by updating the repo documentation and committing everything together:

1. Update the inventory tables in [`README.md`](../README.md)
2. Update [`docs/keybindings.md`](keybindings.md) if new keybindings were introduced
3. Update [`docs/theming.md`](theming.md) if the change affects colors, fonts or appearance
4. Commit everything, following the convention in [`CONTRIBUTING.md`](../CONTRIBUTING.md):

```bash
git add -A
git commit -m "FEAT(<scope>): description of the change"
```
