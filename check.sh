#!/usr/bin/env bash
# Checks the policy page before and after publishing.
#   ./check.sh            # the local index.html
#   ./check.sh --live     # the published page
set -euo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
if [[ "${1:-}" == --live ]]; then
  PAGE=$(curl -fsS https://danieldominguez8.github.io/loteria-privacy/)
  TERMS=$(curl -fsS https://danieldominguez8.github.io/loteria-privacy/terms.html) || fail "terms page not published"
else
  PAGE=$(cat "$(dirname "$0")/index.html")
  TERMS=$(cat "$(dirname "$0")/terms.html")
fi
grep -q "enlace" <<<"$PAGE" || fail "no voice-link section (es)"
grep -q "Cloudflare" <<<"$PAGE" || fail "Cloudflare not named as processor"
grep -q "no tenemos servidores" <<<"$PAGE" && fail "still says 'no tenemos servidores'"
grep -qi "we have no servers" <<<"$PAGE" && fail "still says 'we have no servers'"
grep -q 'id="soporte"' <<<"$PAGE" || fail "no #soporte section"
grep -q 'id="support"' <<<"$PAGE" || fail "no #support section"
grep -q "ARCO" <<<"$PAGE" || fail "no ARCO rights section"
# 2026-10-26: the stores call the app "Lotería Mexicana Tradicional"; the page says so, and names the old name once per language.
grep -q "<h1>Lotería Mexicana Tradicional</h1>" <<<"$PAGE" || fail "heading not the store name"
grep -q "antes Lotería Tradicional" <<<"$PAGE" || fail "old name not mentioned (es)"
grep -q "formerly Lotería Tradicional" <<<"$PAGE" || fail "old name not mentioned (en)"
grep -q "Actualizado el 26 de octubre de 2026: solo cambia el nombre" <<<"$PAGE" || fail "rename not dated (es)"
grep -q "Updated October 26, 2026: only the app’s name changed" <<<"$PAGE" || fail "rename not dated (en)"
grep -q "iPhone" <<<"$PAGE" || fail "iOS app not covered"
grep -q "Android" <<<"$PAGE" || fail "Android app not covered"
grep -q "5.1" <<<"$PAGE" || fail "link sharing not tied to a version"
grep -q "10 de octubre de 2026" <<<"$PAGE" || fail "effective date not updated"
# 5.5: the apps list and download card decks ("Más barajas") — say so in both languages.
grep -q 'id="barajas"' <<<"$PAGE" || fail "no Más barajas section (es)"
grep -q 'id="decks"' <<<"$PAGE" || fail "no Más barajas section (en)"
grep -q "solo se conecta cuando envías" <<<"$PAGE" && fail "still says it only connects for links (es)"
grep -q "only connects when you send" <<<"$PAGE" && fail "still says it only connects for links (en)"
# The Worker counts deck download starts: say so plainly (no "no analytics" claim that hides it).
grep -q "cuántas veces se empieza a descargar cada baraja" <<<"$PAGE" || fail "download counting not described (es)"
grep -q "how many times each deck starts downloading" <<<"$PAGE" || fail "download counting not described (en)"
# Daily totals per deck version are kept past the ~3 months (loteria-links cron → private R2).
grep -q "el total de descargas iniciadas por día de cada baraja, versión y catálogo" <<<"$PAGE" || fail "daily totals not described (es)"
grep -q "each deck version's total download starts per day, by catalog" <<<"$PAGE" || fail "daily totals not described (en)"
# 5.6: decks from the player's own photos — on the phone only, except a PDF the player shares.
grep -q 'id="mis-barajas"' <<<"$PAGE" || fail "no Mis barajas section (es)"
grep -q 'id="my-decks"' <<<"$PAGE" || fail "no Mis barajas section (en)"
grep -q "Nosotros nunca las recibimos" <<<"$PAGE" || fail "photos-stay-on-phone not stated (es)"
grep -q "We never receive them" <<<"$PAGE" || fail "photos-stay-on-phone not stated (en)"
grep -q "PDF con tablas que incluye tus fotos" <<<"$PAGE" || fail "PDF share not described (es)"
grep -q "PDF of tablas that includes your photos" <<<"$PAGE" || fail "PDF share not described (en)"
grep -q "Android 12 o posterior" <<<"$PAGE" || fail "device transfer not scoped to Android 12+ (es)"
grep -q "Android 12 or newer" <<<"$PAGE" || fail "device transfer not scoped to Android 12+ (en)"
# The page must not claim photos stay "only" on the phone: backups and transfers copy them too.
grep -q "se quedan solo en tu teléfono" <<<"$PAGE" && fail "says photos stay only on the phone (es); backups copy them"
grep -q "stay only on your phone" <<<"$PAGE" && fail "says photos stay only on the phone (en); backups copy them"
grep -q 'id="respaldos"' <<<"$PAGE" || fail "no #respaldos anchor"
grep -q 'id="backups"' <<<"$PAGE" || fail "no #backups anchor"
# 2026-11-05: the TV version (Apple TV, Google TV/Android TV, Fire TV, Roku, LG). Apple TV, Roku and LG are offline
# and collect nothing; the Android-based TVs run the Android app, whose startup fetches the deck list
# (LoteriaApp.loadDecks -> deckStore -> refreshCatalogs), so the page must not call those offline.
grep -q 'id="tele"' <<<"$PAGE" || fail "no TV section (es)"
grep -q 'id="tv"' <<<"$PAGE" || fail "no TV section (en)"
grep -q "En Apple TV, Roku y LG no recopila ningún dato y no se conecta a internet" <<<"$PAGE" || fail "offline TVs not stated (es)"
grep -q "On Apple TV, Roku and LG it collects no data and doesn’t connect to the internet" <<<"$PAGE" || fail "offline TVs not stated (en)"
grep -q "al abrirse pide la lista de barajas disponibles, igual que en el teléfono" <<<"$PAGE" || fail "Android TV deck-list fetch not disclosed (es)"
grep -q "when the app starts it asks for the list of available decks, just as on a phone" <<<"$PAGE" || fail "Android TV deck-list fetch not disclosed (en)"
grep -Eq "(Google TV|Android TV|Fire TV)[^.<]*no se conecta a internet" <<<"$PAGE" && fail "says an Android-based TV is offline (es)"
grep -Eq "(Google TV|Android TV|Fire TV)[^.<]*doesn’t connect to the internet" <<<"$PAGE" && fail "says an Android-based TV is offline (en)"
grep -q "y la versión para la tele también por las tiendas de Amazon, Roku y LG" <<<"$PAGE" || fail "TV stores not in the distribution sentence (es)"
grep -q "and the TV version also through the Amazon, Roku and LG stores" <<<"$PAGE" || fail "TV stores not in the distribution sentence (en)"
grep -q "Actualizado el 5 de noviembre de 2026: se agrega la versión para la tele" <<<"$PAGE" || fail "TV update not dated (es)"
grep -q "Updated November 5, 2026: adds the TV version" <<<"$PAGE" || fail "TV update not dated (en)"
# The terms page (the TV stores require a terms URL): linked both ways, both languages, anchors it links to exist.
grep -Fq 'href="terms.html"' <<<"$PAGE" || fail "privacy page doesn't link the terms"
grep -q 'id="uso-aceptable"' <<<"$PAGE" || fail "no #uso-aceptable anchor"
grep -q 'id="acceptable-use"' <<<"$PAGE" || fail "no #acceptable-use anchor"
grep -q "<h1>Lotería Mexicana Tradicional</h1>" <<<"$TERMS" || fail "terms heading not the store name"
grep -q '<h2 id="es">Términos de uso</h2>' <<<"$TERMS" || fail "no Spanish terms"
grep -q '<h2 id="en">Terms of use</h2>' <<<"$TERMS" || fail "no English terms"
grep -Fq 'href="./"' <<<"$TERMS" || fail "terms don't link the privacy page"
for anchor in uso-aceptable acceptable-use respaldos backups; do
  grep -Fq "href=\"./#$anchor\"" <<<"$TERMS" || fail "terms don't link #$anchor"
done
for doc in PAGE TERMS; do
  # Nothing loaded from another origin (scripts, styles, fonts, images, frames).
  if grep -Eoi '<(script|link|img|iframe)[^>]+(src|href)="https?://' <<<"${!doc}"; then fail "third-party resource ($doc)"; fi
  # Outbound links only to the stores and our own domain.
  bad=$(grep -Eo '(src|href)="https?://[^"]+"' <<<"${!doc}" | grep -Ev '^(src|href)="https://(apps\.apple\.com|play\.google\.com|loteriatradicional\.net)(/|")' || true)
  [[ -z "$bad" ]] || fail "unexpected outbound link ($doc): $bad"
done
if [[ "${1:-}" != --live ]]; then
  (cd "$(dirname "$0")" && npx --yes html-validate@9 index.html terms.html >/dev/null) || fail "html-validate"
fi
echo "policy checks: all passed"
