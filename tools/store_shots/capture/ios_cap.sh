#!/bin/bash
# usage: ios_cap.sh market locale kind out  (GRID=1, WAIT=n)
D=$(cat /tmp/iphone_id); M=$1; L=$2; K=$3; O=$4
case $K in
  shot:*) J="\"CW_SHOT\":\"${K#shot:}\"";;
  route:*) J="\"CW_ROUTE\":\"${K#route:}\"";;
esac
C=$(xcrun simctl get_app_container $D com.volkan.walletapp data)
mkdir -p "$C/Documents"
printf '{"CW_GRID":"%s","CW_DEMO":"2","CW_MARKET":"%s","CW_LOCALE":"%s","CW_THEME":"light",%s}' "${GRID:-0}" "$M" "$L" "$J" > "$C/Documents/cw_demo.json"
xcrun simctl terminate $D com.volkan.walletapp >/dev/null 2>&1
xcrun simctl launch $D com.volkan.walletapp >/dev/null
sleep ${WAIT:-12}
xcrun simctl io $D screenshot --type=png /tmp/mk9/ios/$O.png >/dev/null 2>&1
echo $O
