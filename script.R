# source : https://github.com/bnosac/audio.whisper
# install.packages("languageserver")
# install.packages("rmarkdown")
# remotes::install_github("ManuelHentschel/vscDebugger")
# install.packages(
#                  "httpgd",
#                  repos = c(
#                            "https://nx10.r-universe.dev",
#                            "https://cran.r-project.org"))

print("-------- Installation de audio.whisper --------")

print(Sys.time())
# Vulkan pour accélération AMD GPU (RX 6950 XT)
Sys.setenv(WHISPER_CMAKE_FLAGS = "-DGGML_VULKAN=1")
remotes::install_github("bnosac/audio.whisper", ref = "0.5.0", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")

print("-------- Installation terminée --------")

library(audio.whisper)

model <- whisper("large-v2", use_gpu = TRUE, flash_attn = TRUE)

# Transcrire un fichier audio
audio_files <- list.files(pattern = "output\\d+.wav")

print("-------- Transcription en cours --------")
print(Sys.time())

transcriptions <- lapply(
  audio_files,
  function(file) {
    transcription <- predict(
      model,
      newdata = file,
      language = "fr",
      n_threads = 14
    )$data$text

    # Regrouper toutes les lignes sous un seul en-tête
    return(paste0("--------------------- ", file, " ------------------------------\n", paste(transcription, collapse = "\n")))
  }
)

print("-------- Transcription terminée --------")
# display the date and hour
print(Sys.time())

print("-------- Sauvegarde de la transcription dans un fichier texte --------")

# Sauvegarder la transcription dans un fichier texte
final_transcription <- paste(transcriptions, collapse = "\n\n")
writeLines(final_transcription, "2026-06-08-carolina.txt")
