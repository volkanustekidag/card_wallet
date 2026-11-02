#!/bin/bash
loc() { case $1 in gb) echo en_US;; mx) echo es_ES;; pt) echo pt_BR;; esac; }
for M in gb mx pt; do L=$(loc $M)
  /tmp/mk9/acap.sh $M $L route:/home ${M}_home
  GRID=1 /tmp/mk9/acap.sh $M $L route:/home ${M}_grid
  /tmp/mk9/acap.sh $M $L shot:checkout ${M}_checkout
  /tmp/mk9/acap.sh $M $L shot:bank ${M}_bank
  /tmp/mk9/acap.sh $M $L shot:confirm ${M}_confirm
  [ $M = pt ] && SETTLE=5 /tmp/mk9/acap.sh $M $L shot:iban ${M}_iban
  /tmp/mk9/acap.sh $M $L route:/home tmp_w >/dev/null; sleep 3
  /tmp/a shell input keyevent KEYCODE_HOME; sleep 4
  /tmp/a exec-out screencap -p > /tmp/mk9/android/${M}_widget.png
  echo "done $M"
done
rm -f /tmp/mk9/android/tmp_w.png
