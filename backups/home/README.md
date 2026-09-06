# imperative state snapshot

Raw copies of config that lives **outside** the flake — GUI-tuned settings that
NixOS/home-manager doesn't manage. Not auto-applied; restore by hand into the
matching path if the machine is rebuilt. Regenerate with the same curation any
time settings drift.

Captured 2026-09-05.

## what's here

| path | source | notes |
|--|--|--|
| `config/*rc`, `config/*.conf` | `~/.config/` | KDE/Plasma: shortcuts (`kglobalshortcutsrc`), colors (`kdeglobals`), kwin, panel layout (`plasma-org.kde.plasma.desktop-appletsrc`), spectacle, dolphin, okular, kate |
| `config/kwinoutputconfig.json` | `~/.config/` | monitor arrangement as set in Plasma |
| `config/kate/`, `config/kdedefaults/`, `config/qt5ct/`, `config/qt6ct/` | `~/.config/` | app dirs |
| `config/fastfetch/`, `config/xsettingsd/`, `config/stylix/`, `config/plasma-workspace/` | `~/.config/` | mostly flake-derived; kept for reference |
| `config/dconf-dump.ini` | `dconf dump /` | GTK/GNOME app settings (nautilus, virt-manager, ProtonPlus, text editor) |
| `config/blender/`, `config/forge/`, `config/mpv/` | `~/.config/` | app config |
| `local-state/settings.toml` | `~/.local/state/noctalia/` | **live Noctalia config — this is ahead of `home.nix`.** GUI writes here and it wins over the flake. Fold keepers back into `home.nix`. |
| `local-state/state.toml`, `*.json` | `~/.local/state/noctalia/` | noctalia recents / usage / palettes catalog |
| `home/gitconfig` | `~/.gitconfig` | just the gh credential-helper wiring |

## deliberately excluded (secrets / churn / regenerated)

- `~/.config/gh/` — GitHub OAuth token
- `~/.config/discord/`, `vesktop/`, `Vencord/` — Discord tokens
- `~/.config/net.imput.helium/`, `~/.config/mozilla/` — browser profiles, cookies, saved logins
- `~/.config/obs-studio/` — logs, profiler data, bundled ingest lists, websocket password
- `~/.config/zoom*` — account state
- `~/.local/state/noctalia/{clipboard,notification_history*,plugin-cache,wallhaven}` — caches / history
- everything home-manager symlinks from the nix store
