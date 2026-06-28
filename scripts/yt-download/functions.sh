#!/bin/bash

# video-download: Download YouTube videos to the current directory
# Usage: video-download URL
_video-download() {
    if [ -z "$1" ]; then
        echo "Usage: video-download URL"
        echo "Example: video-download https://www.youtube.com/watch?v=VIDEO_ID"
        return 1
    fi

    yt-dlp --cookies-from-browser chrome \
           --download-archive "$HOME/scripts/dev-bootstrap/scripts/yt-download/downloaded.txt" \
           --format "bestvideo+bestaudio/best" \
           --extractor-args "youtube:player_client=web" \
           "$1"
}

# noglob wrapper: URLs with ? and & no longer need quoting
alias video-download='noglob _video-download'
