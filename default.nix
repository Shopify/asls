let
  pkgs = import <nixpkgs> {};
in

pkgs.stdenv.mkDerivation rec {
  pname = "asls";
  version = "0.3.0";

  src = pkgs.fetchurl {
    url = "https://github.com/saulecabrera/asls/releases/download/v0.3.0/bin.tar.gz";
    sha256 = "01d6v79zqw62pkv33km090nyn78zxr0vs3yvnw24ykysvqjyaqd3";
  };

  buildInputs = [ pkgs.erlangR22 ];
  installPhase = "install -Dm755 -t $out/bin asls";

  meta = with pkgs.stdenv.lib; {
    description = "AssemblyScript Language Server";
    homepage = "https://github.com/saulecabrera/asls";
  };
}
