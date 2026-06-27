# Projet R pour retranscrire des entretiens

Transcription automatique de fichiers audio en français via [audio.whisper](https://github.com/bnosac/audio.whisper) (whisper.cpp), avec accélération GPU AMD via Vulkan.

## Prérequis

- **Docker** avec support GPU : la carte graphique AMD est exposée au conteneur via `--device=/dev/dri`
- **GPU AMD** avec driver Mesa/RADV (testé sur RX 6950 XT). Pour un GPU NVIDIA, remplacer Vulkan par CUDA.
- VS Code avec l'extension **Dev Containers**

## Lancer le projet

1. Ouvrir le dossier dans VS Code → **Reopen in Container**  
   Le `post-create.sh` installe automatiquement toutes les dépendances (ffmpeg, Vulkan, etc.)

2. Placer les fichiers audio `output000.wav`, `output001.wav`, … dans `/workspaces/marion/`

3. Modifier le nom du fichier de sortie dans `script.R` (ligne `writeLines`) selon la date et l'interviewé

4. Lancer la transcription :
   ```bash
   Rscript script.R
   ```
   La première exécution recompile `audio.whisper` (~5 min). Le modèle `large-v2` (3 Go) est téléchargé automatiquement si absent.

## Préparer les fichiers audio

Convertir un fichier en WAV 16 kHz mono (requis par Whisper) :

```bash
ffmpeg -i input.wmv -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

Découper en segments de 30 minutes :

```bash
ffmpeg -i interview.wav -f segment -segment_time 1800 -c copy output%03d.wav
```

## Accélération GPU (Vulkan / AMD)

Le script utilise `WHISPER_CMAKE_FLAGS="-DGGML_VULKAN=1"` à la compilation et `use_gpu=TRUE` à l'exécution.

Dépendances installées par `post-create.sh` :

| Paquet                   | Rôle                                                                      |
| ------------------------ | ------------------------------------------------------------------------- |
| `libvulkan-dev`          | Headers + `libvulkan.so` pour cmake                                       |
| `glslc`                  | Compilateur de shaders GLSL (requis par ggml-vulkan)                      |
| `mesa-vulkan-drivers`    | Fournit `radeon_icd.json` — permet au loader Vulkan de trouver le GPU AMD |
| symlink `libvulkan-1.so` | audio.whisper utilise `-lvulkan-1` (nom Windows) même sur Linux           |

Vérifier que le GPU est bien détecté au lancement :

```
ggml_vulkan: Found 1 Vulkan devices:
ggml_vulkan: 0 = AMD Radeon RX 6950 XT (RADV NAVI21) ...
whisper_backend_init_gpu: using Vulkan0 backend
```

Vérifier l'utilisation GPU en temps réel pendant la transcription :

```bash
cat /sys/class/drm/card*/device/gpu_busy_percent
```

Pendant la transcription, le GPU tourne à ~99% et le CPU à ~13% (14 threads).

## Transcrire un message vocal WhatsApp (ou tout fichier audio court)

Pour un fichier court (message vocal, entretien unique), la librairie Python `openai-whisper` est plus simple à utiliser que le pipeline R.

Elle est installée automatiquement par `post-create.sh`. Il suffit ensuite de lancer :

```bash
python3 -c "
import whisper
model = whisper.load_model('small')  # ou 'medium', 'large' pour plus de précision
result = model.transcribe('MonFichier.ogg', language='fr')
print(result['text'])
"
```

Les modèles disponibles, du plus rapide au plus précis :

| Modèle   | Taille | Vitesse | Qualité |
| -------- | ------ | ------- | ------- |
| `tiny`   | 75 Mo  | +++     | +       |
| `small`  | 244 Mo | ++      | ++      |
| `medium` | 769 Mo | +       | +++     |
| `large`  | 1.5 Go | -       | ++++    |

Le modèle est téléchargé automatiquement dans `~/.cache/whisper/` lors du premier appel. Les formats acceptés sont : `.ogg`, `.mp3`, `.wav`, `.m4a`, `.mp4`, etc.

Pour sauvegarder la transcription dans un fichier :

```bash
python3 -c "
import whisper
model = whisper.load_model('small')
result = model.transcribe('MonFichier.ogg', language='fr')
with open('output/2026-06-27-prenom.txt', 'w') as f:
    f.write(result['text'])
"
```

## Transcrire avec ffmpeg (filtre whisper natif, GPU Vulkan)

Grâce à la reconstruction de ffmpeg avec `--enable-whisper` effectuée par `post-create.sh`, le filtre `whisper` est disponible directement dans ffmpeg. Il réutilise la même bibliothèque `whisper.cpp` et les mêmes modèles GGML que le pipeline R, avec accélération GPU Vulkan.

Télécharger un modèle GGML si besoin (le `ggml-large-v2.bin` du pipeline R est déjà utilisable) :

```bash
bash /opt/whisper.cpp/models/download-ggml-model.sh small
# → ggml-small.bin téléchargé dans le répertoire courant
```

Transcrire un fichier audio vers un fichier texte :

```bash
ffmpeg -i "MonFichier.ogg" \
  -af "whisper=model=ggml-small.bin:language=fr:destination=output/2026-06-27-prenom.txt:format=text" \
  -f null -
```

Générer des sous-titres SRT :

```bash
ffmpeg -i "MonFichier.ogg" \
  -af "whisper=model=ggml-large-v2.bin:language=fr:destination=output/2026-06-27-prenom.srt:format=srt" \
  -f null -
```

Options du filtre : `model` (chemin du modèle GGML), `language` (`fr`, `en`, `auto`…), `destination` (fichier ou `-` pour stdout), `format` (`text`, `srt`, `json`).

## Structure du projet

```
script.R          # Script principal de transcription
input/            # Fichiers source (audio brut)
output/           # Transcriptions finées précédentes
tmp/              # Fichiers de travail intermédiaires
output*.wav       # Fichiers WAV segmentés à transcrire (à placer ici)
ggml-large-v2.bin # Modèle Whisper large-v2 (téléchargé automatiquement, 3 Go)
```

Ne pas oublier d'utiliser https://otranscribe.com/ pour parcouir les fichiers WAV et les corriger

Pour lancer le `script.R`, l'interface de VS code montre un bouton "play" normallement
