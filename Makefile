.PHONY: release

SHELL := /bin/bash
MIX_ENV=prod

default: release

release:
	mix local.hex --force
	mix clean
	mix deps.get
	mix escript.build
