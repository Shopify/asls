#!/bin/bash

docker build -f Dockerfile.linux -t asls .
docker cp $(docker create asls:latest):/app ./bin/asls-linux_x86_64

cd bin
tar vzcf asls-linux_x86_64.tar.gz ./asls-linux_x86_64/

rm -rf ./asls-linux_x86_64

echo "Done"
