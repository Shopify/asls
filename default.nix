let
  pkgs = import <nixpkgs> {};
in

pkgs.stdenv.mkDerivation rec {
  pname = "asls";
  version = "0.5.1";

  src = pkgs.fetchurl {
    url = "https://github.com/saulecabrera/asls/releases/download/v${version}/bin.tar.gz";
    sha256 = "05kp44p4q4sdykfw0b4k9j3qdp0qvwgjbs48ncmnd0ass0xrmi3s";
  };

  buildInputs = [ pkgs.erlangR22 ];
  installPhase = "install -Dm755 -t $out/bin asls";

  meta = with pkgs.stdenv.lib; {
    description = "AssemblyScript Language Server";
    homepage = "https://github.com/saulecabrera/asls";
  };
}
