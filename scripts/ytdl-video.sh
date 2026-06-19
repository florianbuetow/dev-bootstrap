#!/bin/bash
# ytdl-video.sh — download a YouTube video (with audio) using yt-dlp.
#
# I/O contract:
#   stdout  : ONLY the path of the downloaded file (one line) on success.
#             Nothing else, ever.
#   stderr  : silent by default. Errors on failure. Debug output only
#             when the DEBUG=true env var is set.
#   exit    : 0 on success, 1 on any error.

set -u

RED='\033[31m'
BLUE='\033[0;34m'
NC='\033[0m'

DEBUG="${DEBUG:-false}"

usage() {
    cat <<'EOF'
Usage: ytdl-video.sh URL [--path PATH] [--filename NAME]

Download a YouTube video (with audio) using yt-dlp.

Always produces one self-contained file. No re-encoding, no
post-processing — whatever YouTube serves as a single ready-to-play
stream is what gets written.

Requires: yt-dlp.

Required
--------
  URL                The YouTube URL. Recognised forms:
                       https://www.youtube.com/watch?v=<id>
                       https://youtube.com/watch?v=<id>
                       https://m.youtube.com/watch?v=<id>
                       https://music.youtube.com/watch?v=<id>
                       https://www.youtube.com/shorts/<id>
                       https://www.youtube.com/embed/<id>
                       https://www.youtube.com/live/<id>
                       https://www.youtube.com/v/<id>
                       https://youtu.be/<id>
                     (http:// variants are also accepted.)

Options
-------
  -p, --path PATH    Destination directory. Defaults to '.' (the
                     current working directory). Created if it does
                     not exist. The printed output path is exactly
                     the path you give plus the filename — pass a
                     relative path to get a relative output path,
                     an absolute path to get an absolute one.

  -f, --filename NAME
                     OPTIONAL — you normally do not need this. If
                     omitted, the file is named
                       <title>-<video_id>.<ext>
                     which is unique per video and stable across runs.
                     Pass NAME (without extension) only if you want to
                     override the default name.

  -h, --help         Show this message and exit.

Environment
-----------
  DEBUG=true         For debugging only. Prints progress and status
                     to stderr while the download is running. Never
                     use this in piped / scripted contexts — even in
                     DEBUG mode the script is guaranteed silent
                     AFTER the final path has been printed to stdout,
                     but the noise during the download is loud.
                     Unset or anything other than 'true' = completely
                     silent on stderr unless an error occurs.

Output contract
---------------
  stdout : ONLY the path of the downloaded file, on a single line.
           Nothing else is ever written to stdout.
  stderr : silent by default. Errors on failure. Debug output only
           when DEBUG=true.
  exit   : 0 success, 1 error.

  Command substitution is therefore always safe:
      f=$(ytdl-video.sh URL) && echo "Got: $f"

Examples
--------
  ytdl-video.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
  ytdl-video.sh https://youtu.be/dQw4w9WgXcQ -p Videos
  DEBUG=true ytdl-video.sh https://youtu.be/dQw4w9WgXcQ
EOF
}

debug() {
    [ "$DEBUG" = "true" ] && printf '%b%s%b\n' "$BLUE" "$*" "$NC" >&2
    return 0
}
fail() { printf '%b✗ %s%b\n' "$RED" "$*" "$NC" >&2; exit 1; }

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi
if [ $# -lt 1 ]; then
    usage >&2
    exit 1
fi

URL="$1"
shift

DEST_PATH="."
FILENAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        -p|--path)
            [ $# -lt 2 ] && fail "$1 requires a value"
            DEST_PATH="$2"; shift 2 ;;
        -f|--filename)
            [ $# -lt 2 ] && fail "$1 requires a value"
            FILENAME="$2"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            fail "Unknown argument: $1" ;;
    esac
done

url_is_youtube() {
    local url="$1"
    [[ "$url" =~ ^https?://(www\.|m\.|music\.)?youtube\.com/(watch\?|shorts/|embed/|live/|v/) ]] && return 0
    [[ "$url" =~ ^https?://youtu\.be/[A-Za-z0-9_-]+ ]] && return 0
    return 1
}

url_is_youtube "$URL" || fail "Not a recognised YouTube URL: $URL"

command -v yt-dlp >/dev/null 2>&1 || fail "yt-dlp not installed"

mkdir -p "$DEST_PATH" || fail "Cannot create destination path: $DEST_PATH"
[ -w "$DEST_PATH" ] || fail "Destination path not writable: $DEST_PATH"

if [ -n "$FILENAME" ]; then
    OUTPUT_TEMPLATE="$DEST_PATH/${FILENAME}.%(ext)s"
else
    OUTPUT_TEMPLATE="$DEST_PATH/%(title)s-%(id)s.%(ext)s"
fi

debug "→ Downloading video to $DEST_PATH"

# Verbosity: --quiet is always set so yt-dlp never leaks info messages
# onto stdout. In DEBUG mode we additionally show its progress bar
# (which goes to stderr) and let its warnings through.
if [ "$DEBUG" = "true" ]; then
    YTDLP_VERBOSITY=(--quiet --progress --newline)
else
    YTDLP_VERBOSITY=(--quiet --no-warnings --no-progress)
fi

RESULT_PATH="$(
    yt-dlp \
        --no-simulate \
        "${YTDLP_VERBOSITY[@]}" \
        --no-playlist \
        --print after_move:filepath \
        -f best \
        -o "$OUTPUT_TEMPLATE" \
        "$URL"
)" || fail "yt-dlp download failed"

RESOLVED_PATH="$(printf '%s\n' "$RESULT_PATH" | tail -n 1)"

[ -n "$RESOLVED_PATH" ] || fail "yt-dlp did not report an output path"
[ -f "$RESOLVED_PATH" ] || fail "Reported output file does not exist: $RESOLVED_PATH"
[ -s "$RESOLVED_PATH" ] || fail "Output file is empty: $RESOLVED_PATH"

# Build the user-facing path: DEST_PATH (verbatim as the user gave it)
# plus the basename of the file yt-dlp actually wrote. This preserves
# the user's path form — relative stays relative, absolute stays
# absolute — instead of leaking yt-dlp's internally-resolved absolute
# path.
BASENAME="$(basename "$RESOLVED_PATH")"
if [ "$DEST_PATH" = "." ]; then
    FINAL_PATH="$BASENAME"
else
    FINAL_PATH="$DEST_PATH/$BASENAME"
fi

debug "✓ Downloaded"

# The final path on stdout MUST be the last thing this script ever
# writes — to either stream. Add nothing after this line.
printf '%s\n' "$FINAL_PATH"
