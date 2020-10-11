.PHONY: release clean mix zip hash test

SHELL := /bin/bash
MIX_ENV=prod

default: release

release: clean mix zip hash

clean:
	rm -rf bin
	rm -rf bin.tar.gz

mix:
	mix local.hex --force
	mix clean
	mix deps.get
	mix escript.build

zip:
	tar cvzf bin.tar.gz bin

hash:
	nix-hash --flat --base32 --type sha256 bin.tar.gz

test: MIX_ENV = test
test:
	mix test
