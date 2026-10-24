#!/bin/bash
loc() { case $1 in au) echo en_US;; ca) echo en_US;; cf) echo fr_FR;; esac; }
for M in au ca cf; do L=$(loc $M)
  WAIT=24 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_home
  GRID=1 WAIT=16 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_grid
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:checkout ${M}_checkout
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:bank ${M}_bank
  WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:confirm ${M}_confirm
  true
done
