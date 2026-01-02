#!/usr/bin/env bash
# natobar - Convert text to NATO phonetic alphabet
# Usage: natobar hello (outputs: Hotel Echo Lima Lima Oscar) | natobar abc 123
# Converts each character to its NATO phonetic equivalent. Supports letters and numbers.
# inspired by: https://robotpaper.ai/useful-bash-scripts/

_natobar_lookup() {
  case "$1" in
    a) echo "Alfa" ;;
    b) echo "Bravo" ;;
    c) echo "Charlie" ;;
    d) echo "Delta" ;;
    e) echo "Echo" ;;
    f) echo "Foxtrot" ;;
    g) echo "Golf" ;;
    h) echo "Hotel" ;;
    i) echo "India" ;;
    j) echo "Juliett" ;;
    k) echo "Kilo" ;;
    l) echo "Lima" ;;
    m) echo "Mike" ;;
    n) echo "November" ;;
    o) echo "Oscar" ;;
    p) echo "Papa" ;;
    q) echo "Quebec" ;;
    r) echo "Romeo" ;;
    s) echo "Sierra" ;;
    t) echo "Tango" ;;
    u) echo "Uniform" ;;
    v) echo "Victor" ;;
    w) echo "Whiskey" ;;
    x) echo "X-ray" ;;
    y) echo "Yankee" ;;
    z) echo "Zulu" ;;
    0) echo "Zero" ;;
    1) echo "One" ;;
    2) echo "Two" ;;
    3) echo "Three" ;;
    4) echo "Four" ;;
    5) echo "Five" ;;
    6) echo "Six" ;;
    7) echo "Seven" ;;
    8) echo "Eight" ;;
    9) echo "Nine" ;;
    *) echo "$1" ;;
  esac
}

natobar() {
  local word
  for word in "$@"; do
    local out=""
    local lower=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    local ch nato
    while [ -n "$lower" ]; do
      ch="${lower:0:1}"
      lower="${lower:1}"
      nato=$(_natobar_lookup "$ch")
      if [ -z "$out" ]; then
        out="$nato"
      else
        out="$out $nato"
      fi
    done
    echo "$out"
  done
}
