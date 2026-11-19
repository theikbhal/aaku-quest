#!/bin/bash
# One command: build → install to /Applications → Desktop shortcut → public GitHub repo
set -e
cd "$(dirname "$0")"
./build.sh
echo "📲 Moving to Applications…"
rm -rf /Applications/AakuQuest.app
cp -R build/AakuQuest.app /Applications/
ln -sf /Applications/AakuQuest.app ~/Desktop/AakuQuest
echo "🖥️  Desktop shortcut created"
if [ ! -d .git ]; then git init -b main; fi
git add . && git commit -m "🥬 Aaku Quest v1" || true
if command -v gh >/dev/null; then
  gh repo create aaku-quest --public --source=. --remote=origin --push \
    --description "Fun Mac app to track buying & eating leafy greens (aaku kuralu) 🥬" || echo "⚠️ Run 'gh auth login' first, then ./setup.sh again"
fi
open /Applications/AakuQuest.app
