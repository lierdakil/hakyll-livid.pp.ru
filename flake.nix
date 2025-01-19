{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
          pkg = pkgs.haskellPackages.callPackage ./package.nix {};
      in pkgs.symlinkJoin {
        inherit (pkg) name version meta;
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/site --set PATH ${pkgs.lib.makeBinPath [ pkgs.lessc ]}";
      };
  };
}
