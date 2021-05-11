#!/bin/bash

docker build -f Dockerfile.linux -t asls .
docker cp $(docker create asls:latest):/app ./bin/asls

cd bin
tar vzcf asls-linux_x86_64.tar.gz ./asls

rm -rf ./asls

echo "Done"
