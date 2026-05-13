{
  lib,
  stdenv,
  makeWrapper,
  jdk25_headless,
}:
stdenv.mkDerivation {
  pname = "converter";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -D ma-eval-1.0-SNAPSHOT-jar-with-dependencies.jar $out/share/java/converter.jar
    makeWrapper ${jdk25_headless}/bin/java $out/bin/converter --add-flags "-jar $out/share/java/converter.jar"
  '';

  meta = {
    mainProgram = "converter";
    description = "Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation";
    homepage = "https://github.com/TUBS-ISF/pb-ddnnf-eval";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
