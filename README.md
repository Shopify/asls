# NOTE
Please note: This repository is currently unmaintained. If you'd like to add features or fix issues, consider creating a fork. Please be aware that we are not going to be updating issues or pull requests on this repository.


# AssemblyScript Language Server
![](https://github.com/saulecabrera/asls/workflows/CI/badge.svg)

A frontend-independent language server for AssemblyScript.

## Installation

Make sure you have [Nix](https://nixos.wiki/wiki/Nix_Installation_Guide) installed, then, run:

```
nix-env -i asls -f https://github.com/saulecabrera/asls/tarball/master/
```

this will make the language server available as a self-contained executable.

Verify that everything was installed correctly with:

```
which asls

asls --version
```

To update the language server to the latest release, run:

```
nix-env -i asls -f https://github.com/saulecabrera/asls/tarball/master/
```

If for some reason you want to install a previous version of the language server, run:

```
nix-env -i asls -f https://github.com/saulecabrera/asls/tarball/v<yourversion>/
```


## Usage

The language server can be used from within any editor front-end that implements
the Language Server Protocol.

To start the server and to start accepting TCP connections on a given port, run:

```sh
asls --port PORT
```

If no port is given, port 7658 is taken as default.

For a detailed explanation of the commands, run:

```sh
asls -h
```

## Features

This project intends to support the following features, in the following order:

- [x] Compilation diagnostics: syntax and/or semantic errors
- [ ] Code completion: complete code that is actually supported by the underlying AS compiler
- [ ] Go-to declaration / definition
- [ ] Information on hover
- [ ] Reference search
- [ ] Formatting

## Development requirements

asls requires:

- Elixir 1.7+
- OTP 22+


### Using nix shell and direnv

If you don't want to worry about installing the required dependencies for
development, you can opt to use nix and direnv. This will ensure that when
switching to the directory of the project, the correct dependencies will be
loaded.

Requirements:

1. Have nix installed
2. Have [direnv](https://direnv.net/) installed; make sure to [hook](https://direnv.net/docs/hook.html) your shell
3. Run `direnv allow` in this directory
4. Run `elixir --version` and verify that the version reported is `1.10.4`

### Building

To build the language server:


1. Run `make mix` to install dependencies
2. Run `make build` to build the language server binary, it will be placed under
   `bin/asls`


## Releasing

Create a dedicated commit with

1. Update the CHANGELOG, following the format
2. Update `mix.exs` with the right version
3. Run `make`. The result of running make is a hash used for `default.nix`. Update the hash and the version in `default.nix`
3. Commit the changes specifying the new version in the commit title `v{major}.{minor}.{patch}`
4. Create a release in GitHub, by uploading the `bin.tar.gz`

