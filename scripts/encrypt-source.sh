#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <source-directory> <protected-output-directory> <age-recipient>" >&2
  exit 2
}

[[ $# -eq 3 ]] || usage
source_dir="$(cd "$1" && pwd -P)"
output_dir="$2"
recipient="$3"

command -v age >/dev/null 2>&1 || {
  echo "age is required. Install it from https://age-encryption.org/." >&2
  exit 1
}
[[ -n "$recipient" && "$recipient" == age1* ]] || {
  echo "Recipient must be an age X25519 public recipient (age1...)." >&2
  exit 1
}
[[ -d "$source_dir" ]] || {
  echo "Source directory does not exist." >&2
  exit 1
}
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd -P)"

case "$output_dir/" in
  "$source_dir/"*)
    echo "Output directory must not be inside the plaintext source directory." >&2
    exit 1
    ;;
esac
if find "$source_dir" -type l -print -quit | grep -q .; then
  echo "Symlinks are not accepted; resolve them before encryption." >&2
  exit 1
fi

count=0
while IFS= read -r -d '' file; do
  relative="${file#"$source_dir"/}"
  target="$output_dir/$relative.age"
  mkdir -p "$(dirname "$target")"
  age --encrypt --recipient "$recipient" --output "$target" "$file"
  count=$((count + 1))
done < <(find "$source_dir" -type f -print0)

if (( count == 0 )); then
  echo "No regular source files found; nothing encrypted." >&2
  exit 1
fi
echo "Encrypted $count file(s). Only the .age ciphertext files belong in the public repository."
