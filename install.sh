#!/usr/bin/env bash
set -e

echo "🔥 yt-dlp Universal Setup"

# Detect Termux vs Linux/WSL
if [[ "$PREFIX" == *"com.termux"* ]]; then
  echo "📱 Termux detected"
  pkg update -y
  pkg install -y yt-dlp aria2 ffmpeg git megatools
  DEFAULT_BASE="$HOME/storage/shared"
else
  echo "🖥️ Linux / WSL detected"
  sudo apt update
  sudo apt install -y yt-dlp aria2 ffmpeg git megatools
  DEFAULT_BASE="$HOME"
fi

echo
read -p "📂 Where to save YouTube videos? (default: $DEFAULT_BASE/Movies): " MOVIES
read -p "🎵 Where to save Music? (default: $DEFAULT_BASE/Music): " MUSIC
read -p "Use SAME folder for PH videos? (y/n): " SAME

MOVIES=${MOVIES:-"$DEFAULT_BASE/Movies"}
MUSIC=${MUSIC:-"$DEFAULT_BASE/Music"}

if [[ "$SAME" == "y" || "$SAME" == "Y" ]]; then
  PHMOVIES="$MOVIES"
else
  read -p "🔞 Where to save PH videos?: " PHMOVIES
  PHMOVIES=${PHMOVIES:-"$DEFAULT_BASE/PH"}
fi

mkdir -p "$MOVIES" "$MUSIC" "$PHMOVIES"

BASHRC="$HOME/.bashrc"

# Remove old block if exists
sed -i '/# ===============================/,/# END yt-dlp shortcuts/d' "$BASHRC" 2>/dev/null || true

cat >> "$BASHRC" <<EOF

# ===============================
# yt-dlp shortcuts (FINAL LIVE)
# ===============================

MOVIES="$MOVIES"
MUSIC="$MUSIC"
PHMOVIES="$PHMOVIES"

ARIA2_ARGS="-x 16 -s 16 -k 1M --file-allocation=trunc"
PROGRESS_FMT="download:%(info.title)s | %(progress._percent_str)s | %(progress._downloaded_bytes_str)s | %(progress._speed_str)s | ETA %(progress._eta_str)s"

yt() {
  yt-dlp -N 16 --downloader aria2c --downloader-args "aria2c:\$ARIA2_ARGS" \
    --quiet --no-warnings --progress --progress-template "\$PROGRESS_FMT" \
    -f "bv*[height<=720][ext=mp4]+ba/b[height<=720]" \
    --merge-output-format mp4 -o "\$MOVIES/%(title)s.%(ext)s" "\$@"
}

yt4k() {
  yt-dlp -N 16 --downloader aria2c --downloader-args "aria2c:\$ARIA2_ARGS" \
    --quiet --no-warnings --progress --progress-template "\$PROGRESS_FMT" \
    -f "bv*[height<=1080][ext=mp4]+ba/b[height<=1080]" \
    --merge-output-format mp4 -o "\$MOVIES/%(title)s.%(ext)s" "\$@"
}

yts() {
  yt-dlp -N 16 --downloader aria2c --downloader-args "aria2c:\$ARIA2_ARGS" \
    --quiet --no-warnings --progress --progress-template "\$PROGRESS_FMT" \
    -f "bestaudio" --extract-audio --audio-format mp3 --audio-quality 0 \
    --embed-metadata -o "\$MUSIC/%(title)s.%(ext)s" "\$@"
}

ythelp() {
  cat <<'HLP'
yt commands:
  yt <url>    → 720p
  yt4k <url>  → 1080p
  yts <url>   → MP3

ph works ONLY on:
  pornhub.com
  youporn.com
  xhamster.com

Tip: Paste any URL and press Enter.
HLP
}

ph() {
  [ -z "\$1" ] && { echo "Usage: ph <url>"; return 1; }

  URL="\$1"
  TMP="\$HOME/.tmpcookies"
  mkdir -p "\$TMP"

  UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

  case "\$URL" in
    *pornhub.com*) COOKIE_URL="https://mega.nz/file/FpBzSTCS#T1X0T0VLeivXBFow2pRzIeTvkR9eK51xaNQLAr6DPHE" ;;
    *youporn.com*) COOKIE_URL="https://mega.nz/file/8gI1HBjT#4Ep12c_a7FHg0IC4Ktow_DIt3Ujq5LWgkdk7hEOtFok" ;;
    *xhamster.com*) COOKIE_URL="https://mega.nz/file/A8Q0wKwJ#jV417fKcMcGbCsAZpvp9AwgMSs7ujDcV4RtcvwcRfFY" ;;
    *) echo "Unsupported site"; rm -rf "\$TMP"; return 1 ;;
  esac

  megatools dl "\$COOKIE_URL" --path "\$TMP" || { rm -rf "\$TMP"; return 1; }
  COOKIE_FILE=\$(ls "\$TMP"/*.txt 2>/dev/null)

  yt-dlp --cookies "\$COOKIE_FILE" --user-agent "\$UA" --force-ipv4 \
    --retries infinite --fragment-retries infinite --retry-sleep fragment:0.5 \
    --concurrent-fragments 4 --hls-use-mpegts --quiet --no-warnings \
    --progress --progress-template "\$PROGRESS_FMT" \
    -f "bv*[height<=720]/b[height<=720]" --merge-output-format mp4 \
    -o "\$PHMOVIES/%(title)s.%(ext)s" "\$URL"

  rm -rf "\$TMP"
}

__handle_enter() {
  local line="\$READLINE_LINE"
  if [[ "\$line" == http://* || "\$line" == https://* ]]; then
    echo "\$line"
    READLINE_LINE=""
    READLINE_POINT=0
    case "\$line" in
      *youtube.com*|*youtu.be*) yt "\$line" ;;
      *pornhub.com*|*youporn.com*|*xhamster.com*) ph "\$line" ;;
      *) echo "Unknown site: \$line" ;;
    esac
    return
  fi
  builtin bind '"\\C-m":accept-line'
}

bind -x '"\\C-m":__handle_enter'

# END yt-dlp shortcuts
EOF

echo
echo "✅ Setup complete!"
echo "Run: source ~/.bashrc"
echo "Then paste any URL and press Enter."
