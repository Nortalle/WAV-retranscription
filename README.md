# Projet R pour retranscrire des entretiens

## Préparer un fichier WAV

```bash
ffmpeg -i input.wmv -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

Séparer un fichier WAV en plusieurs fichiers de 30 minutes

```bash
ffmpeg -i 2025-01-09-whatsapp-long.wav -f segment -segment_time 1800 -c copy output%03d.wav
```

Ne pas oublier d'utiliser https://otranscribe.com/ pour parcouir les fichiers WAV et les corriger

Pour lancer le `script.R`, l'interface de VS code montre un bouton "play" normallement
