#!/usr/bin/env sh

## Update packages list
sudo apt update

## Install ffmpeg and dependencies for audio.whisper with Vulkan GPU support
# libvulkan-dev : headers + libvulkan.so symlink pour cmake FindVulkan
# glslc : compilateur de shaders GLSL requis par ggml-vulkan au build
# mesa-vulkan-drivers : fournit radeon_icd.json (ICD AMD pour le Vulkan loader)
sudo apt install -y ffmpeg cmake libvulkan-dev glslc mesa-vulkan-drivers
## Symlink requis car le configure script de audio.whisper utilise -lvulkan-1 (nom Windows)
sudo ln -sf /usr/lib/x86_64-linux-gnu/libvulkan.so /usr/lib/x86_64-linux-gnu/libvulkan-1.so
## renderD128 (compute node) doit être accessible pour Vulkan
sudo chmod 666 /dev/dri/renderD128 2>/dev/null || true

pipx install radian

## Install Python openai-whisper for transcribing individual audio files (e.g. WhatsApp voice messages)
pip3 install --break-system-packages openai-whisper
