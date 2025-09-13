{
  description = "Ax Framework - Distributed scanning and cloud infrastructure management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    interlace.url = "github:codingo/Interlace";
    interlace.flake = false;
  };

  outputs = { self, nixpkgs, interlace, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      
      interlace-pkg = pkgs.buildGoModule rec {
        pname = "interlace";
        version = "1.0.0";
        
        src = interlace;
        
        vendorHash = null;
        
        meta = with pkgs.lib; {
          description = "Easily turn single threaded command line applications into a fast, multi-threaded application with CIDR and glob support";
          homepage = "https://github.com/codingo/Interlace";
          license = licenses.mit;
          maintainers = [ ];
        };
      };

      ax-framework = pkgs.stdenv.mkDerivation rec {
        pname = "ax-framework";
        version = "latest";
        
        src = pkgs.fetchFromGitHub {
          owner = "attacksurge";
          repo = "ax";
          rev = "f5be1a2452954a708828257fae9edb472cf8b213";
          sha256 = "sha256-XZgje4OjWN3Ln3quPUDuCcQhVArKQo7cDLzq3GDGF3Q=";
        };
        
        nativeBuildInputs = with pkgs; [ makeWrapper ];
        
        buildInputs = with pkgs; [
          git
          curl
          ruby
          jq
          packer
          doctl
          linode-cli
          ibmcloud-cli
          azure-cli
          awscli2
          rsync
          interlace-pkg
        ];
        
        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/share/ax-framework
          
          cp -r $src/* $out/share/ax-framework/
          
          makeWrapper "$out/share/ax-framework/interact/ax" "$out/bin/ax" \
            --set AX_HOME "$out/share/ax-framework" \
            --set AXIOM_HOME "$out/share/ax-framework" \
            --run "mkdir -p \$HOME/.axiom && ln -sfn $out/share/ax-framework/* \$HOME/.axiom/" \
            --prefix PATH : "${pkgs.lib.makeBinPath buildInputs}"
          
          makeWrapper "$out/share/ax-framework/interact/axiom-configure" "$out/bin/axiom-configure" \
            --set AX_HOME "$out/share/ax-framework" \
            --set AXIOM_HOME "$out/share/ax-framework" \
            --run "mkdir -p \$HOME/.axiom && ln -sfn $out/share/ax-framework/* \$HOME/.axiom/" \
            --prefix PATH : "${pkgs.lib.makeBinPath buildInputs}"
        '';
        
        meta = with pkgs.lib; {
          description = "Ax Framework - Distributed scanning and cloud infrastructure management";
          homepage = "https://ax.attacksurge.com/";
          license = licenses.mit;
          maintainers = [ ];
          platforms = platforms.linux;
          mainProgram = "ax";
        };
      };


    in {
      # Packages
      packages.${system} = {
        default = ax-framework;
        ax-framework = ax-framework;
        interlace = interlace-pkg;
      };
      
      apps.${system} = {
        default = {
          type = "app";
          program = "${ax-framework}/bin/ax";
        };
        ax = {
          type = "app";
          program = "${ax-framework}/bin/ax";
        };
        axiom-configure = {
          type = "app";
          program = "${ax-framework}/bin/axiom-configure";
        };
      };
      
      
      legacyPackages.${system} = {
        ax-framework = ax-framework;
        interlace = interlace-pkg;
      };
      
      nixosModules.ax-framework = { config, pkgs, ... }: {
        environment.systemPackages = [ ax-framework ];
        environment.sessionVariables = {
          AX_HOME = "${ax-framework}/share/ax-framework";
        };
      };
      
      overlays.default = final: prev: {
        ax-framework = ax-framework;
        interlace = interlace-pkg;
      };
    };
}