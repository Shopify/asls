#!/bin/bash

OS="$(uname -s)"

if [ $OS != "Darwin" ]; then
  echo "This release must be invoked from a Mac OS system"
  exit 1
fi

echo "Creating release for"
echo $OS

MIX_ENV=prod mix release --overwrite

echo "Cleaning previous build artifacts"

rm -rf bin/asls
rm -rf bin/asls-mac.tar.gz

echo "Copying release to bin/ directory"
mv _build/prod/rel/asls bin/

echo "Bundling the realse"
cd bin/
tar cvzf asls-mac.tar.gz asls

echo "Done!"


