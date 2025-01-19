{ mkDerivation, base, blaze-html, filepath, hakyll, lib, time }:
mkDerivation {
  pname = "site";
  version = "0.1.0.0";
  src = lib.sourceFilesBySuffices (lib.cleanSource ./.)
    [ "cabal.project" "cabal.project.freeze" ".cabal" ".hs" "LICENSE.md" ];
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base blaze-html filepath hakyll time
  ];
  license = lib.licenses.mit;
  mainProgram = "site";
}
