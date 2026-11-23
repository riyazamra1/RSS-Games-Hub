#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
umask 077

command -v age >/dev/null 2>&1 || { echo "age is required" >&2; exit 1; }
command -v age-keygen >/dev/null 2>&1 || { echo "age-keygen is required" >&2; exit 1; }

identity="$TMP/test-identity.txt"
age-keygen -o "$identity" 2>/dev/null
recipient="$(age-keygen -y "$identity")"

source="$TMP/plain-source"
encrypted="$TMP/encrypted"
restored="$TMP/restored"
mkdir -p "$source/nested" "$encrypted" "$restored"
printf 'RSS source protection round-trip test\n' > "$source/nested/file with spaces.txt"
printf '\x00\x01\x02binary-test\xff' > "$source/binary.dat"

bash "$ROOT/scripts/encrypt-source.sh" "$source" "$encrypted" "$recipient"

while IFS= read -r -d '' cipher; do
  relative="${cipher#"$encrypted"/}"
  relative="${relative%.age}"
  target="$restored/$relative"
  mkdir -p "$(dirname "$target")"
  age --decrypt --identity "$identity" --output "$target" "$cipher"
  cmp "$source/$relative" "$target"
  IFS= read -r header < "$cipher"
  [[ "$header" == "age-encryption.org/v1" ]]
done < <(find "$encrypted" -type f -name '*.age' -print0)

encrypted_count="$(find "$encrypted" -type f -name '*.age' | wc -l | tr -d ' ')"
[[ "$encrypted_count" == "2" ]]
echo "PASS: encryption helper round-tripped $encrypted_count files; plaintext was kept outside the repository."
