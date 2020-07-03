.PHONY: release clean mix zip

SHELL := /bin/bash
MIX_ENV=prod

default: release

release: clean mix zip

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
