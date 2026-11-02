#!/bin/bash
loc() { case $1 in us) echo en_US;; de) echo de_DE;; tr) echo tr_TR;; fr) echo fr_FR;; es) echo es_ES;; it) echo it_IT;; nl) echo nl_NL;; pl) echo pl_PL;; br) echo pt_BR;; esac; }
for M in us de tr fr es it nl pl br; do
  /tmp/mk9/acap.sh $M $(loc $M) route:/home tmp_w >/dev/null
  sleep 3
  /tmp/a shell input keyevent KEYCODE_HOME; sleep 4
  /tmp/a exec-out screencap -p > /tmp/mk9/android/${M}_widget.png
  echo $M
done
rm -f /tmp/mk9/android/tmp_w.png
