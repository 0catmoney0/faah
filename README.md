# FAAH 🎬

Joue automatiquement une vidéo en plein écran quand tu tapes une commande inconnue dans le terminal. Compatible **Windows, macOS, Linux**.

---

## 📦 Installation

### Windows (PowerShell)

Ouvre **PowerShell** (clic droit sur le menu Démarrer → *Terminal* ou *Windows PowerShell*), puis colle :

```powershell
iwr -useb tinyurl.com/faah-win | iex
```

Si tu obtiens une erreur d'`ExecutionPolicy`, lance d'abord :
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### macOS

Ouvre **Terminal** (`Cmd + Espace` → tape "Terminal"), puis colle :

```bash
curl -fsSL tinyurl.com/faah-unix | bash
```

Installe aussi `ffmpeg` (nécessaire pour lire les vidéos) :
```bash
brew install ffmpeg
```

> Si tu n'as pas Homebrew : installe-le via https://brew.sh

### Linux

Ouvre ton terminal habituel (GNOME Terminal, Konsole, etc.), puis colle :

```bash
curl -fsSL tinyurl.com/faah-unix | bash
```

Installe `ffmpeg` selon ta distrib :
```bash
sudo apt install ffmpeg          # Debian, Ubuntu, Mint
sudo dnf install ffmpeg          # Fedora, RHEL
sudo pacman -S ffmpeg            # Arch, Manjaro
```

Pour que la pause auto de Spotify/YouTube fonctionne, installe aussi `playerctl` (optionnel) :
```bash
sudo apt install playerctl
```

---

## 🎬 Comment ajouter / changer la vidéo

1. **Ouvre un nouveau terminal** après installation (sinon le hook n'est pas chargé).

2. Tape `faah` — il te dira **où** poser ta vidéo, en fonction de ton OS :

   | OS | Chemin du dossier |
   |---|---|
   | Windows | `C:\Users\TON_NOM\.faah\media\` |
   | macOS | `/Users/TON_NOM/.faah/media/` |
   | Linux | `/home/TON_NOM/.faah/media/` |

3. **Pose une ou plusieurs vidéos** dans ce dossier. Extensions acceptées : `.mp4`, `.mkv`, `.webm`, `.mov`, `.avi`. Le son doit être inclus dans la vidéo.

4. **Re-tape `faah`** — tu auras un menu pour choisir laquelle utiliser :
   ```
   Dossier video : /home/valen/.faah/media/

   Videos disponibles :
     1) drole.mp4  (active)
     2) error.webm
     3) screamer.mkv

   Choisis une video (1-3, Entree pour garder "drole.mp4") :
   ```
   Tape le numéro ou appuie sur Entrée pour ne rien changer.

5. **Test** : tape une commande qui n'existe pas (ex : `blabla`) → la vidéo joue en plein écran.

---

## ⚙️ Comportement

- 🎵 **Pause automatique des autres médias** avant de jouer (Spotify, YouTube, VLC, Apple Music...). Évite le mélange de sons.
- ⏱️ **Cooldown 10 secondes** : si tu spammes des commandes invalides, la vidéo ne se relance pas avant 10s.
- 🔒 **Une seule instance** : pas de superposition de vidéos.
- 🖥️ **Multi-écran (Windows uniquement)** : la vidéo s'affiche sur tous les moniteurs en même temps.
- 🚪 **Touche Échap** : ferme la fenêtre en urgence.

---

## ❌ Désinstallation

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/0catmoney0/faah/main/uninstall.sh | bash
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/0catmoney0/faah/main/uninstall.ps1 | iex
```

L'uninstaller te demande si tu veux supprimer aussi le dossier `~/.faah/media/` (qui contient tes vidéos).

---

## 🛠️ Dépannage

**La vidéo ne se lance pas.**
- Vérifie qu'une vidéo est bien posée dans `~/.faah/media/` (tape `faah` pour voir le statut).
- Sur Mac/Linux : vérifie que `ffmpeg` est installé (`ffplay -version`).
- Sur Windows : ouvre la vidéo avec Windows Media Player pour vérifier qu'elle est lisible.
- Ouvre un **nouveau** terminal après installation/modification.

**Le son ne sort pas.**
- Vérifie que le son est inclus **dans le fichier vidéo** (pas un fichier audio séparé).
- Vérifie le volume Windows/macOS et le bon périphérique de sortie.

**Le hook PowerShell ne se charge pas.**
- Lance `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- Vérifie que `$PROFILE.CurrentUserAllHosts` contient bien `. "C:\Users\...\.faah\lib\faah_hook.ps1"`.

---

## Liens

- Repo : https://github.com/0catmoney0/faah
- Install court Mac/Linux : https://tinyurl.com/faah-unix
- Install court Windows : https://tinyurl.com/faah-win
