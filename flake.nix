{
  description = "Zola blog development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zola
            nodejs
            yarn
          ];

          shellHook = ''
            echo "Zola development environment loaded"
            echo "Run 'zola serve' to start the development server"
          '';
        };

         packages.default = pkgs.writeShellScriptBin "serve" ''
           ${pkgs.zola}/bin/zola serve
         '';

         packages.build = pkgs.writeShellScriptBin "build" ''
           ${pkgs.zola}/bin/zola build
         '';
      }
    );
}
