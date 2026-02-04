#!/bin/sh

# Builds all three rotations of the DUP client package

cd ../priv/static

for ROTATION_INDEX in {0..2}; do
  echo "export const ROTATION_INDEX = ${ROTATION_INDEX};" > ../../assets/src/components/dup/rotation_index.tsx && \
  npm --prefix ../../assets run deploy:dup && \
  cp -r css/packaged_dup.css js/packaged_dup.js js/packaged_dup.js.map ../dup_preview.png ../dup-app.html . && \
  cp ../dup_template.json ./template.json && \
  sed -i "" "s/DUP APP ./DUP APP ${ROTATION_INDEX}/" template.json && \
  zip -r dup-app-${ROTATION_INDEX}.zip packaged_dup.css packaged_dup.js fonts images dup-app.html template.json dup_preview.png
done
