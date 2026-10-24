#!/bin/bash
# Mirror of .context/runapp for iOS simulator shots: ML Kit without its
# iOS pods (they ship no arm64 simulator slice).
set -e
SRC=/Users/volkanustekidag/conductor/workspaces/card_wallet/bishkek
R=$SRC/.context/runapp
D=$SRC/.context/iosrun
mkdir -p $D
rsync -a --delete --exclude build --exclude ios/Pods --exclude ios/Podfile.lock --exclude .dart_tool --exclude android/.gradle --exclude stubs $R/ $D/
rsync -a --delete $R/stubs/ $D/stubs/
rsync -a --exclude Pods --exclude Podfile.lock $SRC/ios/ $D/ios/
python3 - "$D/pubspec.yaml" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
s=s.replace("""dependency_overrides:
  google_mlkit_commons: ^0.11.1""","""dependency_overrides:
  google_mlkit_commons:
    path: stubs/google_mlkit_commons
  google_mlkit_barcode_scanning:
    path: stubs/google_mlkit_barcode_scanning
  google_mlkit_text_recognition:
    path: stubs/google_mlkit_text_recognition""")
open(p,'w').write(s)
PY
python3 /tmp/ios_patch.py "$D"
python3 /tmp/watch_patch.py "$D"
cd $D && flutter pub get >/dev/null && echo synced
