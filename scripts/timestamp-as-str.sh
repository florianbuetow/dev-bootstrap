#!/usr/bin/env zsh

export LC_TIME=en_US.UTF-8
d=$(date +%-d)
case $d in
  11|12|13) s=th ;;
  *1) s=st ;;
  *2) s=nd ;;
  *3) s=rd ;;
  *) s=th ;;
esac
printf "Note: The current date is %s the %s%s of %s and it is %s o'clock." "$(date +%A)" "$d" "$s" "$(date +%B)" "$(date +%H:%M)"
