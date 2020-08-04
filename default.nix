let
  pkgs = import <nixpkgs> {};
in

pkgs.stdenv.mkDerivation rec {
  pname = "asls";
  version = "0.4.2";

  src = pkgs.fetchurl {
    url = "https://github.com/saulecabrera/asls/releases/download/v${version}/bin.tar.gz";
    sha256 = "0phmf9idzzzqidl4h9zhxhxhv80m78irlp4i39z1fp5w7xsrq6ca";
  };

  buildInputs = [ pkgs.erlangR22 ];
  installPhase = "install -Dm755 -t $out/bin asls";

  meta = with pkgs.stdenv.lib; {
    description = "AssemblyScript Language Server";
    homepage = "https://github.com/saulecabrera/asls";
  };
}
