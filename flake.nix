{
  description = "A very basic flake";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkpost = pkgs.writeShellScriptBin "mkpost" ''
        hugo new "posts/$(date +'%Y-%m-%d')-$1.md"
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          hugo
          mkpost
        ];
      };
    };
}
