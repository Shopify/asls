.PHONY: setup

SHELL := /bin/bash

default: release

release:
	mix local.hex --force
	mix clean
	mix deps.get
	mix escript.build
