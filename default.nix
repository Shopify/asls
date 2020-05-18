{ stdenv
  , makeWrapper
  , fetchFromGitHub
  , elixir_1_7
  , erlangR22
}:

stdenv.mkDerivation rec {
  name = "asls";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "saulecabrera";
    repo = "asls";
    rev = "v${version}";
    sha256 = "182iyb529zp119bkw54jiifsh55nrca65vfpwa3bz0l31bb3zzq5";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ erlangR22 elixir_1_7 ];

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/bin/asls $out/bin/asls
    chmod +x $out/bin/asls
    wrapProgram $out/bin/asls --prefix PATH ":" ${erlangR22}/bin ;
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/saulecabrera/asls;
  };
}


