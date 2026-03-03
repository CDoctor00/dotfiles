# Managing Configurations

This document explains how to add, remove, and maintain configurations tracked in this repo.

Configurations are managed in two different ways depending on where they live on the system. User-space configs (under `$HOME`) are handled with **GNU Stow**, which creates symlinks so that any edit is immediately reflected in the repo. System-level files (under `/etc` or `/usr/share`) require root access and cannot be symlinked, so they are managed via **install/sync scripts** that copy files in both directions.

---

## Stow packages

### Adding a new package

```bash
# 1. Create the stow package structure inside configs/
mkdir -p ~/coding/dotfiles/configs/<new_package>/.config/<new_package>

# 2. Move the existing config from the system into the repo
mv ~/.config/<new_package> ~/coding/dotfiles/configs/<new_package>/.config/

# 3. Create the symlink with stow
stow --dir=/home/user/coding/dotfiles/configs --target=/home/user <new_package>

# 4. Verify the symlink was created correctly
ls -la ~/.config/<new_package>
# Expected: ~/.config/<new_package> -> /home/user/coding/dotfiles/configs/<new_package>/.config/<new_package>
```

For files that live directly in `$HOME` (like `.bashrc`):

```bash
mkdir -p ~/coding/dotfiles/configs/<new_package>
mv ~/.<new_package>rc ~/coding/dotfiles/configs/<new_package>/.<new_package>rc
stow --dir=/home/user/coding/dotfiles/configs --target=/home/user <new_package>
```

### Removing a package

To remove symlinks without deleting files from the repo:

```bash
stow --dir=/home/user/coding/dotfiles/configs --target=/home/user -D <new_package>
```

---

## System files

### Adding a new system file

System files are tracked in `scripts/system-files.conf` — both `install.sh` and `sync.sh` read from it automatically.

```bash
# 1. Create the folder structure inside system/
mkdir -p ~/coding/dotfiles/system/<new_entry>/

# 2. Copy the file from the system into the repo
sudo cp /etc/<new_file>.conf ~/coding/dotfiles/system/<new_entry>/
sudo chown $USER:$USER ~/coding/dotfiles/system/<new_entry>/<new_file>.conf

# 3. Add the mapping to scripts/system-files.conf
echo "system/<new_entry>/<new_file>.conf:/etc/<new_file>.conf" >> ~/coding/dotfiles/scripts/system-files.conf
```

From now on:

- `./sync.sh --system-only` will copy the file from the system back into the repo
- `./install.sh --system-only` will deploy it from the repo to the system

---

## After any change

Whether you added a Stow package or a system file, always close the loop by updating the repo documentation and committing everything together:

1. Update the inventory tables in [`README.md`](../README.md)
2. Update [`docs/keybindings.md`](keybindings.md) if new keybindings were introduced
3. Update [`docs/theming.md`](theming.md) if the change affects colors, fonts or appearance
4. Commit everything:

```bash
git add -A
git commit -m "FEAT: description of the change"
```
