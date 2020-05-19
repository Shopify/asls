# nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'
{ stdenv
  , makeWrapper
  , fetchFromGitHub
  , elixir_1_7
  , erlangR22
}:

stdenv.mkDerivation rec {
  name = "asls";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "saulecabrera";
    repo = "asls";
    rev = "v${version}";
    sha256 = "1dhgl15cj34bdi4ld7p36hir54hkv4ak2wrdvf3b0881qsii82v0";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ erlangR22 elixir_1_7 ];

  buildPhase = ''
    mkdir -p $PWD/.hex
    export HOME=$PWD/.hex
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/asls $out/bin/asls
    chmod +x $out/bin/asls
    wrapProgram $out/bin/asls --prefix PATH ":" ${erlangR22}/bin ;
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/saulecabrera/asls;
  };
}


