#!/bin/bash
loc() { case $1 in gb) echo en_US;; mx) echo es_ES;; pt) echo pt_BR;; esac; }
for M in gb mx pt; do L=$(loc $M)
  WAIT=24 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_home
  GRID=1 WAIT=16 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_grid
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:checkout ${M}_checkout
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:bank ${M}_bank
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:confirm ${M}_confirm
  [ $M = pt ] && WAIT=18 /tmp/mk9/ios_cap.sh $M $L shot:iban ${M}_iban
done
