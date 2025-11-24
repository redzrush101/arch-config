# arch-config

Declarative package management configuration for Arch Linux.

## Structure

- `config.yaml` - Main configuration file
- `packages/base.yaml` - Base packages for all machines
- `packages/hosts/` - Host-specific package configurations
- `packages/modules/` - Optional package modules (supports subdirectories)
- `scripts/` - Post-install hook scripts
- `udev-rules/` - Custom udev rules
- `state/` - Auto-generated state files (git-ignored)

## Usage

### Add base packages
Edit `packages/base.yaml` to add packages that should be installed on all machines.

### Add host-specific packages
Edit `packages/hosts/archlinux.json` to add packages specific to this machine.

### Create and enable modules
1. Create a new YAML file in `packages/modules/` (or in subdirectories like `packages/modules/category/`)
2. Enable it with: `dcli module enable <module-name>` or `dcli module enable category/module-name`
3. Sync packages: `dcli sync`

Note: Modules can be organized in subdirectories for better organization (e.g., `window-managers/hyprland.yaml`)

### Sync packages
```bash
dcli sync           # Preview and install missing packages
dcli sync --prune   # Also remove packages not in configuration
```

## Git Integration

Initialize a git repository to track your configuration:

```bash
cd /home/yassin/.config/arch-config
git init
git add .
git commit -m "Initial arch-config setup"
```

The `state/installed.yaml` file is auto-generated and git-ignored.
