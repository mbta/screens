#!/bin/sh

# Builds all three rotations of the DUP client package.

set -eu

if [ $# -eq 0 ]; then
  version=$(git rev-parse --short HEAD)
  echo "No version string specified, defaulting to current git rev: ${version}"
else
  version=$1
  echo "Using specified version string: ${version}"
fi

npm --prefix assets run deploy:dup

outdir=priv/packaged
rm -r $outdir 2> /dev/null || :
mkdir -p $outdir
cd $outdir

mv ../static/packaged_dup.css* ../static/js/packaged_dup.js* .
cp -r ../static/fonts ../static/images ../dup_preview.png .

rotation_index=0
while [ $rotation_index -le 2 ]; do
  cp ../dup-app.html .
  cp ../dup_template.json template.json
  sed -i "" "s/%rotation%/$rotation_index/" dup-app.html template.json
  sed -i "" "s/%version%/$version/" dup-app.html
  zip -qr "dup-app-$rotation_index-$version.zip" fonts images dup-app.html dup_preview.png packaged_dup.css* packaged_dup.js* template.json

  rotation_index=$((rotation_index + 1))
done

echo
echo "📦 Packages built in: $outdir"
