.PHONY: setup

SHELL := /bin/bash

default: setup

setup:
	mix local.hex --force
	mix clean
	mix deps.get
	mix escript.build
