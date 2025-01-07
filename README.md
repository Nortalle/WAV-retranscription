# Projet R pour retranscrire des entretiens

## Préparer un fichier WAV

```bash
ffmpeg -i input.m4a -acodec pcm_s16le -ac 1 -ar 16000 output.wav
```
