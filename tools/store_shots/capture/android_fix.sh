#!/bin/bash
loc() { case $1 in us) echo en_US;; de) echo de_DE;; tr) echo tr_TR;; fr) echo fr_FR;; es) echo es_ES;; it) echo it_IT;; nl) echo nl_NL;; pl) echo pl_PL;; br) echo pt_BR;; esac; }
for f in $(cat /tmp/mk9/android_bad.txt); do
  b=${f%.png}; M=${b%%_*}; K=${b#*_}; L=$(loc $M)
  case $K in
    home) /tmp/mk9/acap.sh $M $L route:/home $b;;
    grid) GRID=1 /tmp/mk9/acap.sh $M $L route:/home $b;;
    *) /tmp/mk9/acap.sh $M $L shot:$K $b;;
  esac
  echo "$b $L"
done
echo ALLDONE
