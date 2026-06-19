#!/bin/bash
# transcribe.sh — single-file transcription pipeline using the
# batch-transcribe-with-whisper-mlx-local-apple-silicon project.
#
# Usage:
#   transcribe.sh INPUT [OUTPUT] [NAMESPACE] [MODEL] [LANGUAGE]
#
# Stages: ffmpeg → WAV → mlx-whisper → SRT remap → hallucination cleaner.
# After each successful stage the previous stage's artefacts are deleted.
# Final cleaned .txt and .srt are moved into <OUTPUT>/<NAMESPACE>/.

set -u

GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

PROJECT_DIR="$HOME/Developer/github/batch-transcribe-with-whisper-mlx-local-apple-silicon"

usage() {
    cat <<EOF
Usage: transcribe.sh INPUT [OUTPUT] [NAMESPACE] [MODEL] [LANGUAGE]

End-to-end single-file transcription pipeline:
  media file → WAV (silence removed) → Whisper transcript →
  hallucination-cleaned .txt and .srt with original-timeline timestamps,
  moved into <OUTPUT>/<NAMESPACE>/.

Arguments
---------
  INPUT      (required) Local file path OR a URL fetched via yt-dlp.
             Accepted file extensions:
               mp4, m4a, mp3, wav, webm, ogg, mov, m4v, mkv, avi, flv, aiff

  OUTPUT     (optional) Destination folder for the final .txt and .srt.
             If omitted, defaults to:
               \$PROJECT/data/output    ($PROJECT_DIR/data/output)

  NAMESPACE  (optional) Subfolder placed under OUTPUT — final path becomes
             <OUTPUT>/<NAMESPACE>/. If omitted, files are written directly
             into OUTPUT (no subfolder).

  MODEL      (optional) Whisper model to use. One of:
               tiny       fastest, multilingual (auto-detect language)
               tiny-en    fastest, English-only (enforces language=en)
               medium     balanced, multilingual (auto-detect language)
               medium-en  balanced, English-only (enforces language=en)
               large      slowest, best quality, multilingual
             If MODEL is omitted, the default is:
               medium-en  when LANGUAGE=en
               medium     otherwise

  LANGUAGE   (optional) ISO language code, e.g. en, de, fr.
             If omitted, the Whisper model auto-detects the language
             (for multilingual models). The -en models always enforce en.

Validation
----------
If MODEL is English-only (name ends with -en) and LANGUAGE is set to
anything other than 'en', the script exits with status 1 before doing
any work.

Examples
--------
  transcribe.sh ./episode.mp4
      → cleaned files go to \$PROJECT/data/output/ using model 'medium'.

  transcribe.sh https://www.youtube.com/watch?v=xxx /tmp/out
      → downloads via yt-dlp, writes to /tmp/out/.

  transcribe.sh ./episode.mp4 ~/Transcripts podcasts
      → cleaned files go to ~/Transcripts/podcasts/.

  transcribe.sh ./interview.m4a ~/Transcripts work medium-en
      → uses the medium English-only model, enforces language=en.

  transcribe.sh ./rede.aiff ~/Transcripts german "" de
      → uses default model 'medium' with German language hint.

The script reuses the project at:
  \$PROJECT = $PROJECT_DIR
EOF
}

if [ $# -lt 1 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    [ $# -lt 1 ] && exit 1 || exit 0
fi

INPUT="$1"
OUTPUT="${2:-}"
NAMESPACE="${3:-}"
MODEL="${4:-}"
LANGUAGE="${5:-}"

if [ -z "$MODEL" ]; then
    if [ "$LANGUAGE" = "en" ]; then
        MODEL="medium-en"
    else
        MODEL="medium"
    fi
fi

if [ -z "$OUTPUT" ]; then
    OUTPUT="$PROJECT_DIR/data/output"
fi

case "$MODEL" in
    *-en)
        if [ -n "$LANGUAGE" ] && [ "$LANGUAGE" != "en" ]; then
            printf "${RED}✗ Model '%s' is English-only but LANGUAGE='%s' was requested.${NC}\n" "$MODEL" "$LANGUAGE" >&2
            exit 1
        fi
        ;;
esac

case "$MODEL" in
    tiny)       MODEL_REPO="mlx-community/whisper-tiny";          MODEL_LANG="$LANGUAGE" ;;
    tiny-en)    MODEL_REPO="mlx-community/whisper-tiny";          MODEL_LANG="en" ;;
    medium)     MODEL_REPO="mlx-community/whisper-medium-mlx";    MODEL_LANG="$LANGUAGE" ;;
    medium-en)  MODEL_REPO="mlx-community/whisper-medium-mlx";    MODEL_LANG="en" ;;
    large)      MODEL_REPO="mlx-community/whisper-large-v3-mlx";  MODEL_LANG="$LANGUAGE" ;;
    *)
        printf "${RED}✗ Unknown MODEL: '%s' (expected: tiny, tiny-en, medium, medium-en, large)${NC}\n" "$MODEL" >&2
        exit 1
        ;;
esac

if [ ! -d "$PROJECT_DIR" ]; then
    printf "${RED}✗ Project directory not found: %s${NC}\n" "$PROJECT_DIR" >&2
    exit 1
fi

for required_script in scripts/prepare_audio.sh scripts/transcribe.sh scripts/clean_transcripts.py; do
    if [ ! -f "$PROJECT_DIR/$required_script" ]; then
        printf "${RED}✗ Required project script missing: %s/%s${NC}\n" "$PROJECT_DIR" "$required_script" >&2
        exit 1
    fi
done

if ! command -v ffmpeg >/dev/null 2>&1; then
    printf "${RED}✗ ffmpeg not installed${NC}\n" >&2
    exit 1
fi

is_url=false
case "$INPUT" in
    http://*|https://*) is_url=true ;;
esac

if [ "$is_url" = false ] && [ ! -f "$INPUT" ]; then
    printf "${RED}✗ Input file not found: %s${NC}\n" "$INPUT" >&2
    exit 1
fi

if [ "$is_url" = true ] && ! command -v yt-dlp >/dev/null 2>&1; then
    printf "${RED}✗ yt-dlp not installed (required for URL inputs)${NC}\n" >&2
    exit 1
fi

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
TEMP_DATA="$(mktemp -d -t transcribe-XXXXXXXX)"
CATEGORY="single"
TEMP_INPUT_DIR="$TEMP_DATA/input/$CATEGORY"
mkdir -p "$TEMP_INPUT_DIR"

FINAL_DIR="$OUTPUT"
if [ -n "$NAMESPACE" ]; then
    FINAL_DIR="$OUTPUT/$NAMESPACE"
fi

printf "\n${BLUE}=== transcribe.sh ===${NC}\n"
printf "  Input:     %s\n" "$INPUT"
printf "  Model:     %s\n" "$MODEL"
printf "  Language:  %s\n" "${MODEL_LANG:-<auto-detect>}"
printf "  Namespace: %s\n" "${NAMESPACE:-<none>}"
printf "  Output:    %s\n" "$FINAL_DIR"
printf "  Temp:      %s\n\n" "$TEMP_DATA"

fail() {
    printf "${RED}✗ %s${NC}\n" "$1" >&2
    printf "${RED}  Temp dir kept for debugging: %s${NC}\n" "$TEMP_DATA" >&2
    exit 1
}

if [ "$is_url" = true ]; then
    printf "${YELLOW}→ Downloading from URL...${NC}\n"
    yt-dlp -f "bestaudio[ext=m4a]/bestaudio" -o "$TEMP_INPUT_DIR/%(title)s.%(ext)s" "$INPUT" \
        || fail "yt-dlp download failed"
else
    printf "${YELLOW}→ Staging local file...${NC}\n"
    cp "$INPUT" "$TEMP_INPUT_DIR/" || fail "Failed to copy input file"
fi

STAGED=""
while IFS= read -r -d '' file; do
    STAGED="$file"
    break
done < <(find "$TEMP_INPUT_DIR" -maxdepth 1 -type f -print0)

if [ -z "$STAGED" ]; then
    fail "No staged input file found in $TEMP_INPUT_DIR"
fi
if [ ! -s "$STAGED" ]; then
    fail "Staged input file is empty: $STAGED"
fi
BASE_NAME="$(basename "$STAGED")"
BASE="${BASE_NAME%.*}"

cd "$PROJECT_DIR" || fail "Cannot cd into project dir: $PROJECT_DIR"

printf "\n${YELLOW}→ Stage 1/3: convert to WAV (with silence removal)...${NC}\n"
DATA_DIR="$TEMP_DATA" REMOVE_SILENCE=true bash scripts/prepare_audio.sh \
    || fail "prepare_audio failed"

printf "\n${YELLOW}→ Stage 2/3: transcribe with %s...${NC}\n" "$MODEL"
DATA_DIR="$TEMP_DATA" MODEL_NAME="$MODEL" MODEL_REPO="$MODEL_REPO" LANGUAGE="$MODEL_LANG" \
    bash scripts/transcribe.sh \
    || fail "transcribe failed"

printf "${YELLOW}→ Removing stage 1 artefacts (WAV + silence map)...${NC}\n"
rm -rf "$TEMP_DATA/output/$CATEGORY/wav"

printf "\n${YELLOW}→ Stage 3/3: clean hallucinations...${NC}\n"
DATA_DIR="$TEMP_DATA" MODEL="$MODEL" uv run python scripts/clean_transcripts.py \
    || fail "clean_transcripts failed"

CLEAN_DIR="$TEMP_DATA/output/$CATEGORY/transcripts_cleaned/$MODEL"
CLEAN_TXT="$CLEAN_DIR/$BASE.txt"
CLEAN_SRT="$CLEAN_DIR/$BASE.srt"

for produced in "$CLEAN_TXT" "$CLEAN_SRT"; do
    if [ ! -f "$produced" ]; then
        fail "Cleaned transcript file not produced: $produced"
    fi
    if [ ! -s "$produced" ]; then
        fail "Cleaned transcript file is empty: $produced"
    fi
done

printf "${YELLOW}→ Removing stage 2 artefacts (uncleaned transcripts)...${NC}\n"
rm -rf "$TEMP_DATA/output/$CATEGORY/transcripts"

mkdir -p "$FINAL_DIR" || fail "Cannot create output dir: $FINAL_DIR"

printf "\n${YELLOW}→ Moving cleaned transcripts to %s${NC}\n" "$FINAL_DIR"
mv "$CLEAN_TXT" "$FINAL_DIR/" || fail "Failed to move .txt"
mv "$CLEAN_SRT" "$FINAL_DIR/" || fail "Failed to move .srt"

rm -rf "$TEMP_DATA"

printf "\n${GREEN}✓ transcribe completed successfully${NC}\n"
printf "  Wrote: %s/%s.txt\n" "$FINAL_DIR" "$BASE"
printf "  Wrote: %s/%s.srt\n\n" "$FINAL_DIR" "$BASE"
