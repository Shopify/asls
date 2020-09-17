{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = [ pkgs.elixir_1_10 pkgs.erlangR22 ];
}
