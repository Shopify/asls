#!/bin/bash

OS="$(uname -s)"

if [ $OS != "Darwin" ]; then
  echo "This release must be invoked from a Mac OS system"
  exit 1
fi

echo "Creating release for Mac"

mix release --overwrite

echo "Copying release to bin/ directory"
mv _build/prod/rel/asls bin/

echo "Bundling the realse"
cd bin/
tar cvzf asls-darwin.tar.gz asls

rm -rf asls

cd ..

echo "Done!"


