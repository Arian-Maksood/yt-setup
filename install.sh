#!/usr/bin/env bash
set -e

echo "🔥 yt-dlp Universal Setup"

# Detect platform
if [[ "$PREFIX" == *"com.termux"* ]]; then
  PLATFORM="termux"
  echo "📱 Termux detected"
  pkg update -y
  pkg install -y yt-dlp aria2 ffmpeg git megatools

  DEF_MOVIES="$HOME/storage/shared/Movies"
  DEF_MUSIC="$HOME/storage/shared/Music"
else
  PLATFORM="linux"
  echo "🖥️ Linux / WSL detected"
  sudo apt update
  sudo apt install -y yt-dlp aria2 ffmpeg git megatools

  DEF_MOVIES="$HOME/Videos"
  DEF_MUSIC="$HOME/Music"
fi

echo
echo "Default paths:"
echo "  Movies: $DEF_MOVIES"
echo "  Music : $DEF_MUSIC"

read -p "Use default paths? (y/n): " USEDEF < /dev/tty

case "$USEDEF" in
  y|Y|"")
    MOVIES="$DEF_MOVIES"
    MUSIC="$DEF_MUSIC"
    ;;
  *)
    read -p "Enter Movies path: " MOVIES < /dev/tty
    read -p "Enter Music path: " MUSIC < /dev/tty
    ;;
esac

read -p "Use SAME folder for PH videos? (y/n): " SAME < /dev/tty

case "$SAME" in
  y|Y|"")
    PHMOVIES="$MOVIES"
    ;;
  *)
    read -p "Enter PH video path: " PHMOVIES < /dev/tty
    ;;
esac

mkdir -p "$MOVIES" "$MUSIC" "$PHMOVIES"

# Fix Termux storage permissions
if [[ "$PLATFORM" == "termux" ]]; then
  chmod -R 775 "$MOVIES" "$MUSIC" "$PHMOVIES"
fi

BASHRC="$HOME/.bashrc"
touch "$BASHRC"

# Remove old block
sed -i '/# ===============================/,/# END yt-dlp shortcuts/d' "$BASHRC" 2>/dev/null || true

cat >> "$BASHRC" <<'EOF'

# ===============================
# yt-dlp shortcuts (FINAL LIVE)
# ===============================

MOVIES="__MOVIES__"
MUSIC="__MUSIC__"
PHMOVIES="__PHMOVIES__"

ARIA2_ARGS="-x 16 -s 16 -k 1M --file-allocation=trunc"

PROGRESS_FMT="download:%(info.title)s | %(progress._percent_str)s | %(progress._downloaded_bytes_str)s | %(progress._speed_str)s | ETA %(progress._eta_str)s"

yt() {
  yt-dlp -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet --no-warnings --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bv*[height<=720][ext=mp4]+ba/b[height<=720]" \
    --merge-output-format mp4 \
    -o "$MOVIES/%(title)s.%(ext)s" "$@"
}

yt4k() {
  yt-dlp -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet --no-warnings --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bv*[height<=1080][ext=mp4]+ba/b[height<=1080]" \
    --merge-output-format mp4 \
    -o "$MOVIES/%(title)s.%(ext)s" "$@"
}

yts() {
  yt-dlp -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet --no-warnings --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bestaudio" \
    --extract-audio --audio-format mp3 \
    --audio-quality 0 --embed-metadata \
    -o "$MUSIC/%(title)s.%(ext)s" "$@"
}

# END yt-dlp shortcuts
EOF

sed -i "s|__MOVIES__|$MOVIES|g" "$BASHRC"
sed -i "s|__MUSIC__|$MUSIC|g" "$BASHRC"
sed -i "s|__PHMOVIES__|$PHMOVIES|g" "$BASHRC"

echo
echo "✅ Setup complete!"
echo "Run: source ~/.bashrc"sed -i "s|__MOVIES__|$MOVIES|g" "$BASHRC"
sed -i "s|__MUSIC__|$MUSIC|g" "$BASHRC"
sed -i "s|__PHMOVIES__|$PHMOVIES|g" "$BASHRC"

echo
echo "✅ Setup complete!"
echo "Run: source ~/.bashrc"
