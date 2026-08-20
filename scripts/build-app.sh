#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/dist/FreeJerem.app"
contents_dir="$app_dir/Contents"

cd "$project_dir"
swift build -c release

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp ".build/release/FreeJerem" "$contents_dir/MacOS/FreeJerem"
cp "Resources/Info.plist" "$contents_dir/Info.plist"

codesign --force --sign - "$app_dir"
echo "$app_dir"
