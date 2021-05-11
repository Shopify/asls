.PHONY: release clean mix test build nix mac linux

SHELL := /bin/bash
MIX_ENV=prod

default: release

release: export MIX_ENV=prod
release: clean mix mac linux

clean:
	rm -rf bin/nix
	rm -rf bin/*.tar.gz
	rm -rf bin/asls

mix:
	mix local.hex --force
	mix clean
	mix deps.get

mac:
	./bin/release_mac.sh

linux:
	./bin/release_linux.sh

test: export MIX_ENV=test
test:
	mix test

build: export MIX_ENV=prod
build:
	mix escript.build
