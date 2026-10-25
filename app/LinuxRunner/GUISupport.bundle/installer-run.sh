#!/bin/sh
# Normal UI installation entrypoint. Always retain compiler/package stderr.
set -eu
cd "$(dirname "$0")"
case "${1:-}" in install.sh|install-qt.sh|install-browser.sh|install-desktop.sh|desktop-profile.sh) installer=$1;; *) exit 2;; esac
shift
# desktop-profile.sh takes only its fixed verbs.
for arg in "$@"; do case "$arg" in repair|accounts|sudo|plasma) ;; *) exit 2;; esac; done
. ./package-lock.sh
rm -f install-result
log="$installer.log"
printf 'SUPPORT_INSTALL: script=%s started; package/compiler output retained
' "$installer" > "$log"
tail -n +1 -f "$log" & reader=$!
code=0
# The lock wait (first-start configuration, other package operations) is part
# of the log, and every outcome ends with install-result for the app.
if package_lock_acquire >> "$log" 2>&1; then
    /bin/sh "./$installer" "$@" >> "$log" 2>&1 || code=$?
else
    code=$?
fi
kill "$reader" 2>/dev/null || true; wait "$reader" 2>/dev/null || true
printf '
SUPPORT_INSTALL: script=%s exit=%s
' "$installer" "$code" >> "$log"
tail -n 12 "$log"
printf '%s
' "$code" > install-result.tmp; mv install-result.tmp install-result
exit "$code"
