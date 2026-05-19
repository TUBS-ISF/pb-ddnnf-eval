{
  description = "Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    d4 = {
      url = "github:SoftVarE-Group/d4v2/2.3.2";
    };
    ddnnife = {
      url = "github:SoftVarE-Group/d-dnnf-reasoner/0.10.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    p2d = {
      url = "github:uulm-janbaudisch/p2d/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pbcount = {
      url = "git+https://github.com/uulm-janbaudisch/pbcount?ref=nix&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opb2pbcount = {
      url = "github:uulm-janbaudisch/opb2pbcount/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      d4,
      ddnnife,
      p2d,
      pbcount,
      opb2pbcount,
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
          d4 = d4.packages.${system}.default;
          ddnnife = ddnnife.packages.${system}.default;
          p2d = p2d.packages.${system}.default;
          pbcount = pbcount.packages.${system}.default;
          opb2pbcount = opb2pbcount.packages.${system}.default;
          converter = pkgs.callPackage ./converter/default.nix { };
          container = pkgs.dockerTools.buildLayeredImage {
            name = "pb-ddnnf-eval";
            contents = [
              pkgsSelf.d4
              pkgsSelf.ddnnife
              pkgsSelf.p2d
              pkgsSelf.pbcount
              pkgsSelf.opb2pbcount
              pkgsSelf.converter
              pkgs.time
            ];
            config = {
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
