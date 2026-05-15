# FAAH

Joue une vidéo en plein écran quand une commande shell échoue.

## Installation (one-liner court)

### macOS / Linux (bash ou zsh)

```bash
curl -fsSL tinyurl.com/faah-unix | bash
```

### Windows (PowerShell)

```powershell
iwr -useb tinyurl.com/faah-win | iex
```

Dépendance Mac/Linux : `ffmpeg`. L'installeur indique la commande adaptée (`brew install ffmpeg`, `sudo apt install ffmpeg`...).

## Utilisation

1. Pose ta vidéo dans `~/.faah/media/video.mp4` (extension libre : `.mp4`, `.mkv`, `.webm`...).
2. Ouvre un nouveau terminal (ou recharge ton shell).
3. **Auto** : tape une commande inconnue → la vidéo joue.
4. **Manuel** : tape juste `faah` → la vidéo joue tout de suite (sans cooldown).

## Comportement

- **Cooldown 10s** entre deux déclenchements auto (pas de spam).
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

## URLs complètes (si besoin)

- Repo : https://github.com/0catmoney0/faah
- install.sh : https://raw.githubusercontent.com/0catmoney0/faah/main/install.sh
- install.ps1 : https://raw.githubusercontent.com/0catmoney0/faah/main/install.ps1
