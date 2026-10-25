#!/bin/sh
# Run only in an isolated guest fixture with the canonical support deployed.
set -eu
cd /home/mobile/Downloads/.linuxrunner/gui
for name in 'x;id' '-y' '../bad' 'two names'; do
 code=0; /bin/sh package-manager.sh install "$name" || code=$?
 [ "$code" = 2 ] || exit 1
done
code=0; /bin/sh package-manager.sh upgrade || code=$?; [ "$code" = 2 ]
# A real second managed operation must refuse a live owner.
/bin/sh -c '. ./package-lock.sh; package_lock_acquire; sleep 3' package-manager.sh & locker=$!
while [ ! -f .install-lock/pid ]; do sleep .05; done
code=0; /bin/sh package-manager.sh installed || code=$?; [ "$code" = 75 ]
wait "$locker"
# Recover only an abandoned managed lock, not the distro package database.
mkdir .install-lock; echo 999999 > .install-lock/pid
/bin/sh package-manager.sh installed
[ "$(cat package-result)" = 0 ] && [ -s package-state.tsv ] && [ ! -d .install-lock ]
/bin/sh package-manager.sh search xterm
[ "$(cat package-result)" = 0 ] && grep -q xterm package-state.tsv
/bin/sh package-manager.sh details xterm
[ "$(cat package-result)" = 0 ] && [ -s package-details.txt ]
/bin/sh package-manager.sh dependencies
[ "$(cat package-result)" = 0 ]
echo 'PACKAGE_MANAGER_PASS invalid argv, live lock, stale lock, real installed/search/details/dependency state'
