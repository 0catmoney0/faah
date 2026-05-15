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

1. Tape **`faah`** dans ton terminal → il te dit exactement où poser ta vidéo.
2. Pose ta vidéo dans `~/.faah/media/video.mp4` (extension libre : `.mp4`, `.mkv`, `.webm`...). Le son doit être inclus dans la vidéo.
3. Ouvre un nouveau terminal (ou recharge ton shell).
4. Tape une commande inconnue → la vidéo joue en plein écran.

## Comportement

- **Pause auto des autres médias** : Spotify, YouTube, VLC etc. sont mis en pause avant que la vidéo joue (Windows 10+, macOS, Linux avec `playerctl`).
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
