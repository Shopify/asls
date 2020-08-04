let
  pkgs = import <nixpkgs> {};
in

pkgs.stdenv.mkDerivation rec {
  pname = "asls";
  version = "0.4.2";

  src = pkgs.fetchurl {
    url = "https://github.com/saulecabrera/asls/releases/download/v${version}/bin.tar.gz";
    sha256 = "0d4z2zwpq87d6p0z983ay71n7m7cb39vmrgr8269snh10r4q0hzn";
  };

  buildInputs = [ pkgs.erlangR22 ];
  installPhase = "install -Dm755 -t $out/bin asls";

  meta = with pkgs.stdenv.lib; {
    description = "AssemblyScript Language Server";
    homepage = "https://github.com/saulecabrera/asls";
  };
}
