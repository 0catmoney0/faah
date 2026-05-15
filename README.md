# FAAH

Joue une vidéo en plein écran quand une commande shell échoue.

## Installation (one-liner)

### macOS / Linux (bash ou zsh)

```bash
curl -fsSL https://raw.githubusercontent.com/0catmoney0/faah/main/install.sh | bash
```

Dépendance : `ffmpeg`. L'installeur indique la commande adaptée si absent (`brew install ffmpeg` sur Mac, `sudo apt install ffmpeg` sur Debian/Ubuntu...).

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/0catmoney0/faah/main/install.ps1 | iex
```

## Utilisation

1. Pose ta vidéo dans `~/.faah/media/video.mp4` (extension libre : `.mp4`, `.mkv`, `.webm`...).
2. Ouvre un nouveau terminal (ou recharge ton shell).
3. Tape une commande inconnue → la vidéo joue en plein écran avec le son.

## Comportement

- **Cooldown 10s** entre deux déclenchements (pas de spam).
- **Single instance** : si une vidéo joue déjà, la suivante est ignorée.
- **Multi-écran (Windows uniquement)** : la vidéo s'affiche sur tous les moniteurs.
- **Échap** : ferme la fenêtre en urgence.

## Désinstallation

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/0catmoney0/faah/main/uninstall.sh | bash
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/0catmoney0/faah/main/uninstall.ps1 | iex
```

## Changer la vidéo

Remplace simplement le fichier dans `~/.faah/media/`. Le nom doit commencer par `video.` (extension libre). Pas besoin de réinstaller.
