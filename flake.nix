{
  description = "tunecopy";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url  = "github:numtide/flake-utils";

    pyrin.url  = "github:nanoteck137/pyrin/v0.20.1";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        version = pkgs.lib.strings.fileContents "${self}/version";
        fullVersion = ''${version}-${self.dirtyShortRev or self.shortRev or "dirty"}'';

        app = pkgs.buildGoModule {
          pname = "tunecopy";
          version = fullVersion;
          src = ./.;

          ldflags = [
            "-X github.com/nanoteck137/tunecopy.Version=${version}"
            "-X github.com/nanoteck137/tunecopy.Commit=${self.dirtyRev or self.rev or "no-commit"}"
          ];

          vendorHash = "sha256-6PHasHDkTEXxYVaA+FFHpsISpFg8RD0w7pGqHA8CV2c=";
        };
      in
      {
        packages = {
          default = app;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            air
            go
            gopls
            just

            inputs.pyrin.packages.${system}.default
          ];
        };
      }
    );
}
