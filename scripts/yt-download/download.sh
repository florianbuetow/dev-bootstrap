#!/bin/bash

yt-dlp --cookies-from-browser firefox --download-archive downloaded.txt --format "bestvideo+bestaudio/best" "$@"
