#!/usr/bin/env bash
# Checks house style across the vault. Run from anywhere:
#   bash .claude/scripts/check-style.sh
# Exits 0 if clean, 1 if anything needs fixing.
#
# Scope: everything except "02 - Deep Dives" (legacy notes, predate these rules)
# and raw attendee captures, which are preserved as written.
#
# A line containing the word "banned" is skipped, so the rule lists in
# CLAUDE.md and CONTRIBUTING.md do not flag themselves.

set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

FAIL=0

EXCLUDE='02 - Deep Dives|\.git/|\.obsidian/|\.remember/|Software Architects Meetup\.md'

echo "Checking for em dashes..."
if grep -rn "—" --include="*.md" . | grep -Ev "$EXCLUDE" | grep -vi "banned\|em dash"; then
  echo "  FAIL: em dashes found. Use commas, colons, periods or parentheses."
  FAIL=1
else
  echo "  ok"
fi

echo "Checking for AI-tell phrasing..."
WORDS='genuinely|worth noting|the kind of thing|delve|leverage|seamless|robust|crucial|testament to|showcases|underscores|at its core|in the world of|dive into|Here.s the thing'
if grep -rnE -i "$WORDS" --include="*.md" . | grep -Ev "$EXCLUDE" | grep -vi "banned"; then
  echo "  FAIL: banned phrasing found. See CONTRIBUTING.md section 3."
  FAIL=1
else
  echo "  ok"
fi

echo "Checking for angle-bracket placeholders in headings..."
# Skips fenced code blocks, where <Placeholder> headings are legitimate examples.
STRIPPED=$(find . -name "*.md" | grep -Ev "$EXCLUDE" | while read -r f; do
  awk -v F="$f" '/^```/{fence=!fence; next} !fence && /^#.*<[A-Za-z]/{print F":"FNR": "$0}' "$f"
done)
if [ -n "$STRIPPED" ]; then
  echo "$STRIPPED"
  echo "  FAIL: markdown parses <like this> as an HTML tag and the heading renders blank."
  FAIL=1
else
  echo "  ok"
fi

echo "Checking for unresolved wikilinks..."
MISSING=0
grep -rhoE "\[\[[^]|#]+" --include="*.md" "01 - Events" "03 - Glossary" 2>/dev/null \
  | sed 's/^\[\[//' | sort -u | while read -r link; do
    [ -z "$link" ] && continue
    if ! find . -name "$link.md" -not -path "./.git/*" | grep -q .; then
      echo "  missing: [[$link]]"
    fi
  done
echo "  (any 'missing' lines above need a note creating, usually in 03 - Glossary)"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Style check passed."
else
  echo "Style check FAILED. Fix the above before committing."
fi
exit "$FAIL"
