
install.packages("languageserver")
install.packages("rmarkdown")
remotes::install_github("ManuelHentschel/vscDebugger")
install.packages(
                 "httpgd",
                 repos = c(
                           "https://nx10.r-universe.dev",
                           "https://cran.r-project.org"))
Sys.setenv(WHISPER_CFLAGS = "-mavx -mavx2 -mfma -mf16c")
remotes::install_github("bnosac/audio.whisper", ref = "0.3.3", force = TRUE)
Sys.unsetenv("WHISPER_CFLAGS")

print("-------- Installation terminée --------")

#amélioration
Sys.setenv(WHISPER_THREADS = "16")
Sys.setenv(WHISPER_OPENBLAS = "1")

library(audio.whisper)

model <- whisper("large-v2", use_gpu = TRUE)

# Transcrire un fichier audio
audio_file <- "STEPHANE.wav"

print("-------- Transcription en cours --------")
transcription <- predict(model, newdata = audio_file, language = "fr", trace = TRUE, n_threads = 16)

print("-------- Transcription terminée --------")

# Afficher la transcription
print(transcription)

print("-------- Sauvegarde de la transcription dans un fichier texte --------")

# Sauvegarder la transcription dans un fichier texte
writeLines(transcription$data$text, "STEPHANE.txt")
