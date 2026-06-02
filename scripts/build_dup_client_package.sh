#!/bin/sh

# Builds DUP client packages. Optionally creates a git tag to record deployment
# of the package to Outfront.

set -eu

is_force=false
is_tagged=false
release_num=0

bold() {
  bold=$(tput bold)
  reset=$(tput sgr0)
  echo "${bold}${1}${reset}"
}

while getopts "fhn:t" opt; do
  case $opt in
  h)
    echo "Options:"
    echo "-h        Show this help"
    echo "-n <num>  Specify a release number for this date (default 0)"
    echo "-t        Create/push a git tag to record deployment of this version"
    echo "-f        Force-push/overwrite the git tag"
    exit
    ;;
  f) is_force=true;;
  n) release_num=$OPTARG;;
  t) is_tagged=true;;
  *)
    >&2 echo "ℹ️ Run with $(bold "-h") for valid options"
    exit 1
    ;;
  esac
done

client_path=assets
if $is_tagged && ! git diff-index --quiet HEAD $client_path; then
  >&2 echo "❌ Refusing to tag a release with uncommitted changes"
  >&2 echo "ℹ️ Commit or stash changes in $(bold $client_path) or run without $(bold "-t")"
  exit 1
fi

version=$(date +%Y.%m.%d).$release_num
tag=dup-$version
prev_tagged_sha=""
head_sha=$(git rev-parse --short HEAD)

if ! $is_tagged; then
  echo "ℹ️ Not creating a release tag (request with $(bold "-t"))"
elif ! [ "$(git tag -l $tag)" ]; then
  echo "ℹ️ Release tag $(bold $tag) will be created"
else
  prev_tagged_sha=$(git rev-parse --short $tag)

  if [ $head_sha = $prev_tagged_sha ]; then
    echo "ℹ️ Release tag $(bold $tag) already exists and points to HEAD"
    is_tagged=false
  elif $is_force; then
    echo "⚠️ Release tag $(bold $tag) already exists and will be overwritten"
  else
    >&2 echo "❌ Release tag $(bold $tag) already exists"
    >&2 echo "ℹ️ Overwrite with $(bold "-f") or choose a different release number with $(bold "-n <num>")"
    exit 1
  fi
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
  zip -qr "dup-app-$rotation_index-v$version.zip" fonts images dup-app.html dup_preview.png packaged_dup.css* packaged_dup.js* template.json

  rotation_index=$((rotation_index + 1))
done

echo
echo "📦 Packages built in: $(bold $outdir)"

if $is_tagged; then
  opts=""
  if $is_force; then opts="-f"; fi

  git tag $opts $tag > /dev/null

  if [ -n "$prev_tagged_sha" ]; then
    echo "⚠️ Updated tag $(bold $tag) to $(bold $head_sha) (was $(bold $prev_tagged_sha))"
  else
    echo "🏷️ Tag $(bold $tag) created at $(bold $head_sha)"
  fi

  git push --quiet $opts origin $tag

  echo "📤 Tag pushed to origin"
fi
