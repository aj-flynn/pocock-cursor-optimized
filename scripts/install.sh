#!/usr/bin/env bash
# Copy this repo's Cursor skills and the engineering-session rule into another project.
# Windows PowerShell opens this file instead of running it. Use scripts/install.ps1 there.
set -euo pipefail

usage() {
  echo "Usage: scripts/install.sh <project>" >&2
  echo "Windows PowerShell: .\\scripts\\install.ps1 <project>" >&2
  echo "Copy these skills into <project>/.cursor/skills and the engineering-session rule into <project>/.cursor/rules." >&2
  exit 2
}

if [[ $# -ne 1 ]]; then
  usage
fi

if [[ ! -d "$1" ]]; then
  echo "Not a directory: $1" >&2
  exit 1
fi

SOURCE_ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
TARGET=$(cd "$1" && pwd -P)

if [[ "$SOURCE_ROOT" == "$TARGET" ]]; then
  echo "Refusing to install into this repo. The skills already live in .cursor/ here." >&2
  exit 1
fi

case "$TARGET/" in
  "$SOURCE_ROOT/"*)
    echo "Refusing to install into a directory inside this repo." >&2
    exit 1
    ;;
esac

SRC_SKILLS="$SOURCE_ROOT/.cursor/skills"
DEST_SKILLS="$TARGET/.cursor/skills"
mkdir -p "$DEST_SKILLS"

same_dir() {
  local left right
  left=$(stat -c '%d:%i' "$1")
  right=$(stat -c '%d:%i' "$2")
  [[ "$left" == "$right" ]]
}

install_leaf() {
  local src_dir="$1"
  local rel="${src_dir#"$SRC_SKILLS"/}"
  local dest="$DEST_SKILLS/$rel"
  if [[ -e "$dest" ]] && same_dir "$src_dir" "$dest"; then
    echo "Refusing to replace $dest because it is the source directory." >&2
    exit 1
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src_dir" "$dest"
  echo "installed skill $rel"
}

while IFS= read -r skill_md; do
  skill_dir=$(dirname "$skill_md")
  rel="${skill_dir#"$SRC_SKILLS"/}"
  if find "$skill_dir" -mindepth 2 -name SKILL.md -print -quit | grep -q .; then
    dest="$DEST_SKILLS/$rel"
    mkdir -p "$dest"
    while IFS= read -r -d '' file; do
      cp -a "$file" "$dest/"
      echo "installed file $rel/$(basename "$file")"
    done < <(find "$skill_dir" -mindepth 1 -maxdepth 1 -type f -print0)
  else
    install_leaf "$skill_dir"
  fi
done < <(find "$SRC_SKILLS" -name SKILL.md | sort)

mkdir -p "$TARGET/.cursor/rules"
cp -a "$SOURCE_ROOT/.cursor/rules/engineering-session.mdc" "$TARGET/.cursor/rules/engineering-session.mdc"
echo "installed rule engineering-session.mdc"

if [[ -f "$TARGET/.gitignore" ]]; then
  if ! grep -qxF '.scratch/' "$TARGET/.gitignore" && ! grep -qxF '.scratch' "$TARGET/.gitignore"; then
    printf '\n# Engineering session state\n.scratch/\n' >> "$TARGET/.gitignore"
    echo "appended .scratch/ to .gitignore"
  fi
else
  echo "No .gitignore in the target. Add .scratch/ so the engineering session file stays uncommitted."
fi
