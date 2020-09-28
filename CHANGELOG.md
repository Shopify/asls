# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [TCP] Improve error reporting if an error occurs

## [0.5.0] - 2020-09-02

### Added
- [TCP] Allow dynamic port assignment

## [0.4.2] - 2020-08-03

### Added
- [Diagnostic Parser] Fix edge cases in diagnostic parsing

## [0.4.1] - 2020-07-19

### Added
- [TCP] Added initial logging stdout and stderr messages

## [O.4.0] - 2020-07-03

### Added
- [CLI] Added the `--version` flag
- [Installation] Added `default.nix` with this, the server can be installed with
  `nix-env -i asls -f https://github.com/saulecabrera/asls/tarball/master/`

## [0.3.0] - 2020-06-16

### Added
- [Diagnostics] Extended the diagnostics parser to extract diagnostics from arbitrary strings.
- [RPC] Added a mechanism to wrap all RPC messages with a single interface using `JsonRpc.Message`
- [Server] Trigger build on configuration change and on document save. From this change on
  diagnostics are published to the language client.
  The server tracks:
  - Build state
  - Build diagnostics
  - Opened documents
  - Whether a rebuild is needed

## [0.2.0] - 2020-06-02

### Added
- [TCP] Added TCP module
- [RPC] Added basic JSON RPC module
- [RPC] Added structures to handle: request, response and notification messages
- [Server] Added basic server 
- [Server] Handle initialize request
- [CLI] Added basic CLI args `--port PORT` or `-p PORT` to start the server on a given port
- [CLI] Added debug option `[-d | --debug]`, which logs incoming  and outgoing messages

### Removed
- [Distribution] Remove `default.nix`. After this release, the binary  will be packed on every release
  and it will be available on nix pkgs.

