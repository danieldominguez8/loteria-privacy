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
grep -q "5 de octubre de 2026" <<<"$PAGE" || fail "effective date not updated"
# 5.5: the apps list and download card decks ("Más barajas") — say so in both languages.
grep -q 'id="barajas"' <<<"$PAGE" || fail "no Más barajas section (es)"
grep -q 'id="decks"' <<<"$PAGE" || fail "no Más barajas section (en)"
grep -q "solo se conecta cuando envías" <<<"$PAGE" && fail "still says it only connects for links (es)"
grep -q "only connects when you send" <<<"$PAGE" && fail "still says it only connects for links (en)"
# The Worker counts deck download starts: say so plainly (no "no analytics" claim that hides it).
grep -q "cuántas veces se empieza a descargar cada baraja" <<<"$PAGE" || fail "download counting not described (es)"
grep -q "how many times each deck starts downloading" <<<"$PAGE" || fail "download counting not described (en)"
# Nothing loaded from another origin (scripts, styles, fonts, images, frames).
if grep -Eoi '<(script|link|img|iframe)[^>]+(src|href)="https?://' <<<"$PAGE"; then fail "third-party resource"; fi
# Outbound links only to the stores and our own domain.
bad=$(grep -Eo '(src|href)="https?://[^"]+"' <<<"$PAGE" | grep -Ev 'https://(apps\.apple\.com|play\.google\.com|loteriatradicional\.net)' || true)
[[ -z "$bad" ]] || fail "unexpected outbound link: $bad"
if [[ "${1:-}" != --live ]]; then
  (cd "$(dirname "$0")" && npx --yes html-validate@9 index.html >/dev/null) || fail "html-validate"
fi
echo "policy checks: all passed"
