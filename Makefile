.PHONY: setup

SHELL := /bin/bash

default: setup

setup:
	mix clean
	mix deps.get
	mix escript.build
