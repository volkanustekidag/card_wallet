#!/bin/bash
loc() { case $1 in au) echo en_US;; ca) echo en_US;; cf) echo fr_FR;; esac; }
for M in au ca cf; do L=$(loc $M)
  /tmp/mk9/acap.sh $M $L route:/home ${M}_home
  GRID=1 /tmp/mk9/acap.sh $M $L route:/home ${M}_grid
  /tmp/mk9/acap.sh $M $L shot:checkout ${M}_checkout
  /tmp/mk9/acap.sh $M $L shot:bank ${M}_bank
  /tmp/mk9/acap.sh $M $L shot:confirm ${M}_confirm
  true
  /tmp/mk9/acap.sh $M $L route:/home tmp_w >/dev/null; sleep 3
  /tmp/a shell input keyevent KEYCODE_HOME; sleep 4
  /tmp/a exec-out screencap -p > /tmp/mk9/android/${M}_widget.png
  echo "done $M"
done
rm -f /tmp/mk9/android/tmp_w.png
