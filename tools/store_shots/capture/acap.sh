#!/bin/bash
# android capture with wait: acap.sh market locale kind out
M=$1; L=$2; K=$3; O=$4
case $K in shot:*) J="\"CW_SHOT\":\"${K#shot:}\"";; route:*) J="\"CW_ROUTE\":\"${K#route:}\"";; esac
printf '{"CW_GRID":"%s","CW_DEMO":"2","CW_MARKET":"%s","CW_LOCALE":"%s","CW_THEME":"light",%s}' "${GRID:-0}" "$M" "$L" "$J" > /tmp/cw_demo_a.json
/tmp/a push /tmp/cw_demo_a.json /data/local/tmp/cw_demo.json >/dev/null 2>&1
/tmp/a shell "run-as com.volkan.wallet_app cp /data/local/tmp/cw_demo.json app_flutter/cw_demo.json"
/tmp/a shell am force-stop com.volkan.wallet_app
/tmp/a shell monkey -p com.volkan.wallet_app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 4
python3 /tmp/mk9/wait_shot.py /tmp/mk9/android/$O.png /tmp/mk9/splash_ref_android.png android ${SETTLE:-3.5}
