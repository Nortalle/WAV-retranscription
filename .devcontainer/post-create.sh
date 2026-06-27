#!/usr/bin/env sh

## Update packages list
sudo apt update

## Install system dependencies
# libvulkan-dev / glslc / mesa-vulkan-drivers : Vulkan pour audio.whisper et whisper.cpp
# build-essential pkg-config yasm nasm   : compilation de whisper.cpp + ffmpeg
# lib*-dev                               : codecs pour ffmpeg (MP3, Opus, Vorbis, VP8/9, H264, H265)
sudo apt install -y cmake libvulkan-dev glslc mesa-vulkan-drivers \
  build-essential pkg-config yasm nasm \
  libmp3lame-dev libopus-dev libvorbis-dev libvpx-dev \
  libx264-dev libx265-dev libssl-dev
## Symlink requis car le configure script de audio.whisper utilise -lvulkan-1 (nom Windows)
sudo ln -sf /usr/lib/x86_64-linux-gnu/libvulkan.so /usr/lib/x86_64-linux-gnu/libvulkan-1.so
## renderD128 (compute node) doit être accessible pour Vulkan
sudo chmod 666 /dev/dri/renderD128 2>/dev/null || true

## ─────────────────────────────────────────────────────────────────────────────
## Build whisper.cpp as a shared library  (~5 min)
## Requis par ffmpeg --enable-whisper ; les modèles GGML sont partagés avec audio.whisper R
## ─────────────────────────────────────────────────────────────────────────────
git clone --depth=1 https://github.com/ggml-org/whisper.cpp.git /opt/whisper.cpp
cmake -S /opt/whisper.cpp -B /opt/whisper.cpp/build \
  -DGGML_VULKAN=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=OFF
cmake --build /opt/whisper.cpp/build -j$(nproc)
sudo cmake --install /opt/whisper.cpp/build
sudo ldconfig

## ─────────────────────────────────────────────────────────────────────────────
## Build ffmpeg 8.1.2 (stable) with --enable-whisper  (~15 min)
## Installé dans /usr/local/bin/ffmpeg (prioritaire sur le ffmpeg système)
## Note : le filtre whisper a été introduit dans ffmpeg 8.0 mais nécessite toujours
##        whisper.cpp comme librairie externe — --enable-whisper linke contre elle.
## ─────────────────────────────────────────────────────────────────────────────
git clone --depth=1 --branch n8.1.2 https://github.com/FFmpeg/FFmpeg.git /opt/FFmpeg
cd /opt/FFmpeg
./configure \
  --prefix=/usr/local \
  --enable-gpl \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-whisper \
  --extra-cflags="-I/usr/local/include" \
  --extra-ldflags="-L/usr/local/lib"
make -j$(nproc)
sudo make install
sudo ldconfig

pipx install radian

## Install Python openai-whisper for transcribing individual audio files (e.g. WhatsApp voice messages)
pip3 install --break-system-packages openai-whisper
