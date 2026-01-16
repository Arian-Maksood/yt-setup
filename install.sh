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
read -p "Use default paths? (y/n): " USEDEF

if [[ "$USEDEF" == "y" || "$USEDEF" == "Y" || -z "$USEDEF" ]]; then
  MOVIES="$DEF_MOVIES"
  MUSIC="$DEF_MUSIC"
else
  read -p "Enter Movies path: " MOVIES
  read -p "Enter Music path: " MUSIC
fi

read -p "Use SAME folder for PH videos? (y/n): " SAME
if [[ "$SAME" == "y" || "$SAME" == "Y" ]]; then
  PHMOVIES="$MOVIES"
else
  read -p "Enter PH video path: " PHMOVIES
fi

mkdir -p "$MOVIES" "$MUSIC" "$PHMOVIES"

# Fix Termux storage permissions
if [[ "$PLATFORM" == "termux" ]]; then
  chmod -R 775 "$MOVIES" "$MUSIC" "$PHMOVIES"
fi

BASHRC="$HOME/.bashrc"

# Remove old block safely
sed -i '/# ===============================/,/# END yt-dlp shortcuts/d' "$BASHRC" 2>/dev/null || true

cat >> "$BASHRC" <<'EOF'

# ===============================
# yt-dlp shortcuts (FINAL LIVE)
# ===============================

MOVIES="__MOVIES__"
MUSIC="__MUSIC__"
PHMOVIES="__PHMOVIES__"

# aria2 (legal + stable)
ARIA2_ARGS="-x 16 -s 16 -k 1M --file-allocation=trunc"

# LIVE single-line progress (safe for YT + HLS)
PROGRESS_FMT="download:%(info.title)s | %(progress._percent_str)s | %(progress._downloaded_bytes_str)s | %(progress._speed_str)s | ETA %(progress._eta_str)s"

# -------- yt (720p) --------
yt() {
  yt-dlp \
    -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet \
    --no-warnings \
    --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bv*[height<=720][ext=mp4]+ba/b[height<=720]" \
    --merge-output-format mp4 \
    -o "$MOVIES/%(title)s.%(ext)s" \
    "$@"
}

# -------- yt4k (1080p) --------
yt4k() {
  yt-dlp \
    -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet \
    --no-warnings \
    --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bv*[height<=1080][ext=mp4]+ba/b[height<=1080]" \
    --merge-output-format mp4 \
    -o "$MOVIES/%(title)s.%(ext)s" \
    "$@"
}

# -------- yts (MP3) --------
yts() {
  yt-dlp \
    -N 16 \
    --downloader aria2c \
    --downloader-args "aria2c:$ARIA2_ARGS" \
    --quiet \
    --no-warnings \
    --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bestaudio" \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 0 \
    --embed-metadata \
    -o "$MUSIC/%(title)s.%(ext)s" \
    "$@"
}

# ===============================
# ph – adult sites (HLS LIVE)
# ===============================

ph() {
  [ -z "$1" ] && { echo "Usage: ph <url>"; return 1; }

  URL="$1"
  TMP="$HOME/.tmpcookies"
  mkdir -p "$TMP"

  UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

  case "$URL" in
    *pornhub.com*)
      COOKIE_URL="https://mega.nz/file/FpBzSTCS#T1X0T0VLeivXBFow2pRzIeTvkR9eK51xaNQLAr6DPHE"
      ;;
    *youporn.com*)
      COOKIE_URL="https://mega.nz/file/8gI1HBjT#4Ep12c_a7FHg0IC4Ktow_DIt3Ujq5LWgkdk7hEOtFok"
      ;;
    *xhamster.com*)
      COOKIE_URL="https://mega.nz/file/A8Q0wKwJ#jV417fKcMcGbCsAZpvp9AwgMSs7ujDcV4RtcvwcRfFY"
      ;;
    *)
      echo "Unsupported site"
      rm -rf "$TMP"
      return 1
      ;;
  esac

  megatools dl "$COOKIE_URL" --path "$TMP" || { rm -rf "$TMP"; return 1; }
  COOKIE_FILE=$(ls "$TMP"/*.txt 2>/dev/null)

  yt-dlp \
    --cookies "$COOKIE_FILE" \
    --user-agent "$UA" \
    --force-ipv4 \
    --retries infinite \
    --fragment-retries infinite \
    --retry-sleep fragment:0.5 \
    --concurrent-fragments 4 \
    --hls-use-mpegts \
    --quiet \
    --no-warnings \
    --progress \
    --progress-template "$PROGRESS_FMT" \
    -f "bv*[height<=720]/b[height<=720]" \
    --merge-output-format mp4 \
    -o "$PHMOVIES/%(title)s.%(ext)s" \
    "$URL"

  rm -rf "$TMP"
}

# ===============================
# Auto-handle pasted URLs (SAFE)
# ===============================

__handle_enter() {
  local line="$READLINE_LINE"

  if [[ "$line" == http://* || "$line" == https://* ]]; then
    echo "$line"
    READLINE_LINE=""
    READLINE_POINT=0

    case "$line" in
      *youtube.com*|*youtu.be*) yt "$line" ;;
      *pornhub.com*|*youporn.com*|*xhamster.com*) ph "$line" ;;
      *) echo "Unknown site: $line" ;;
    esac
    return
  fi

  builtin bind '"\C-m":accept-line'
}

bind -x '"\C-m":__handle_enter'

# END yt-dlp shortcuts
EOF

# Inject chosen paths
sed -i "s|__MOVIES__|$MOVIES|g" "$BASHRC"
sed -i "s|__MUSIC__|$MUSIC|g" "$BASHRC"
sed -i "s|__PHMOVIES__|$PHMOVIES|g" "$BASHRC"

echo
echo "✅ Setup complete!"
echo "Run: source ~/.bashrc"
echo "Then paste any URL and press Enter."
