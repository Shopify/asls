# AssemblyScript Language Server
![](https://github.com/saulecabrera/asls/workflows/CI/badge.svg)

A frontend-independent language server for AssemblyScript.

## Installation

The language server will be distributed as a self-contained executable through
Nix:

```
nix-env -iA nixpkgs.asls
```

This part is not ready yet, for more information see [default.nix](default.nix).


## Usage

The language server can be used from within any editor front-end that implements
the Language Server Protocol.

To start the server and to start accepting TCP connections on a given port, run:

```sh
asls --port PORT
```

If no port is given, port 7658 is taken as default.

## Features

This project intends to support the following features, in the following order:

- [ ] Compilation diagnostics: syntax and/or semantic errors
- [ ] Code completion: complete code that is actually supported by the underlying AS compiler
- [ ] Go-to declaration / definition
- [ ] Information on hover
- [ ] Reference search
- [ ] Formatting

## Development requirements

asls requires:

- Elixir 1.7+
- OTP 22+


## Releasing

Create a dedicated commit with

1. CHANGELOG update, following the format
2. Update `mix.exs` with the right version
3. Commit the changes specifying the new version in the commit title `v{major}.{minor}.{patch}`
4. Create a git tag with the new version `git tag v{major}.{minor}.{patch}`
5. Push the changes to GitHub
6. Create a release
7. Pack the executable with `make release` using `MIX_ENV=prod` and update `bin/asls` to the recently created release

