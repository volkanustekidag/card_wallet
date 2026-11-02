#!/bin/bash
for m in "us en_US" "de de_DE" "tr tr_TR" "fr fr_FR" "es es_ES" "it it_IT" "nl nl_NL" "pl pl_PL" "br pt_BR"; do
  set -- $m; M=$1; L=$2
  WAIT=22 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_home >/dev/null
  GRID=1 WAIT=14 /tmp/mk9/ios_cap.sh $M $L route:/home ${M}_grid >/dev/null
  WAIT=14 /tmp/mk9/ios_cap.sh $M $L shot:checkout ${M}_checkout >/dev/null
  WAIT=14 /tmp/mk9/ios_cap.sh $M $L shot:bank ${M}_bank >/dev/null
  WAIT=14 /tmp/mk9/ios_cap.sh $M $L shot:confirm ${M}_confirm >/dev/null
  if [ $M != us ] && [ $M != br ]; then WAIT=16 /tmp/mk9/ios_cap.sh $M $L shot:iban ${M}_iban >/dev/null; fi
  echo "done $M"
done
echo ALLDONE
