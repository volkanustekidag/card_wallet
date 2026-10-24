#!/bin/bash
OUT=/tmp/mk9/android
for m in "us en_US" "de de_DE" "tr tr_TR" "fr fr_FR" "es es_ES" "it it_IT" "nl nl_NL" "pl pl_PL" "br pt_BR"; do
  set -- $m; M=$1; L=$2
  WAIT=22 /tmp/mk/cap.sh $M $L light route:/home ${M}_home >/dev/null; mv /tmp/mk/${M}_home.png $OUT/
  GRID=1 WAIT=16 /tmp/mk/cap.sh $M $L light route:/home ${M}_grid >/dev/null; mv /tmp/mk/${M}_grid.png $OUT/
  WAIT=16 /tmp/mk/cap.sh $M $L light shot:checkout ${M}_checkout >/dev/null; mv /tmp/mk/${M}_checkout.png $OUT/
  WAIT=16 /tmp/mk/cap.sh $M $L light shot:bank ${M}_bank >/dev/null; mv /tmp/mk/${M}_bank.png $OUT/
  WAIT=16 /tmp/mk/cap.sh $M $L light shot:confirm ${M}_confirm >/dev/null; mv /tmp/mk/${M}_confirm.png $OUT/
  if [ $M != us ] && [ $M != br ]; then WAIT=18 /tmp/mk/cap.sh $M $L light shot:iban ${M}_iban >/dev/null; mv /tmp/mk/${M}_iban.png $OUT/; fi
  echo "done $M"
done
echo ALLDONE
