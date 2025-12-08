{
  description = "Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      lib = nixpkgs.lib;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      formatter = lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      packages = lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgsSelf = self.packages.${system};
        in
        {
          converter = pkgs.callPackage ./converter.nix { };
          container = pkgs.dockerTools.buildLayeredImage {
            name = "pb-ddnnf-eval";
            contents = [
              pkgsSelf.converter
              pkgs.time
            ];
            config = {
              Entrypoint = [ (lib.getExe pkgsSelf.converter) ];
              Labels = {
                "org.opencontainers.image.source" = "https://github.com/uulm-janbaudisch/pb-ddnnf-eval";
                "org.opencontainers.image.description" =
                  "Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation";
              };
            };
          };
        }
      );
    };
}
