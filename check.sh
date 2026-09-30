#!/usr/bin/env bash
# Checks the policy page before and after publishing.
#   ./check.sh            # the local index.html
#   ./check.sh --live     # the published page
set -euo pipefail
if [[ "${1:-}" == --live ]]; then
  PAGE=$(curl -fsS https://danieldominguez8.github.io/loteria-privacy/)
else
  PAGE=$(cat "$(dirname "$0")/index.html")
fi
fail() { echo "FAIL: $1" >&2; exit 1; }
grep -q "enlace" <<<"$PAGE" || fail "no voice-link section (es)"
grep -q "Cloudflare" <<<"$PAGE" || fail "Cloudflare not named as processor"
grep -q "no tenemos servidores" <<<"$PAGE" && fail "still says 'no tenemos servidores'"
grep -qi "we have no servers" <<<"$PAGE" && fail "still says 'we have no servers'"
grep -q 'id="soporte"' <<<"$PAGE" || fail "no #soporte section"
grep -q 'id="support"' <<<"$PAGE" || fail "no #support section"
grep -q "ARCO" <<<"$PAGE" || fail "no ARCO rights section"
grep -q "iPhone" <<<"$PAGE" || fail "iOS app not covered"
grep -q "Android" <<<"$PAGE" || fail "Android app not covered"
grep -q "5.1" <<<"$PAGE" || fail "link sharing not tied to a version"
grep -q "30 de septiembre de 2026" <<<"$PAGE" || fail "effective date not updated"
# Nothing loaded from another origin (scripts, styles, fonts, images, frames).
if grep -Eoi '<(script|link|img|iframe)[^>]+(src|href)="https?://' <<<"$PAGE"; then fail "third-party resource"; fi
# Outbound links only to the stores and our own domain.
bad=$(grep -Eo '(src|href)="https?://[^"]+"' <<<"$PAGE" | grep -Ev 'https://(apps\.apple\.com|play\.google\.com|loteriatradicional\.net)' || true)
[[ -z "$bad" ]] || fail "unexpected outbound link: $bad"
if [[ "${1:-}" != --live ]]; then
  (cd "$(dirname "$0")" && npx --yes html-validate@9 index.html >/dev/null) || fail "html-validate"
fi
echo "policy checks: all passed"
