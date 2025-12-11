{
	description = "Автоматический сборщик системы от Kkleytt"; 

	inputs = {
		# Ветки NixPkgs
		nixpkgs = { url = "github:NixOS/nixpkgs/nixos-25.11"; };
		nixpkgs-unstable = { url = "github:NixOS/nixpkgs/nixos-unstable"; };

		# Установка Home-Manager
		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# Установка WM Hyprland
		hyprland.url = "github:hyprwm/Hyprland";

		# Ссылка на установщик пакетов Flatpak
		nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";

		# Установка темы оформления Caelestia shell 
		quickshell = {
			url = "github:outfoxxed/quickshell";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		caelestia-shell = {
			url = "github:caelestia-dots/shell";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		caelestia-cli = {
			url = "github:caelestia-dots/cli";
			inputs.nixpkgs.follows = "nixpkgs";
		};	

		# Ссылка на тему SDDM
		silentSDDM = {
			url = "github:uiriansan/SilentSDDM";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, ... }:
    let
  		system = "x86_64-linux";
  		host = "mobile";
  		username = "kkleytt";
  		
  		pkgs = import nixpkgs {
  			inherit system;
  			config = {
  				allowUnfree = true;
  				permittedInsecurePackages = [ 
  					"libsoup-2.74.3" 
  				];
  			};
  		};
      pkgsUnstable = import nixpkgs-unstable { inherit system; };
  		lib = nixpkgs.lib;
		
	in {
		nixosConfigurations = {
			mobile = nixpkgs.lib.nixosSystem rec {
				specialArgs = { inherit inputs system username host pkgsUnstable; };
				modules = [ 
					{ nixpkgs.pkgs = pkgs; }
					inputs.nix-flatpak.nixosModules.nix-flatpak
					inputs.home-manager.nixosModules.home-manager
					./hosts/${host}/config.nix 
					./modules/quickshell.nix
					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.backupFileExtension = "backup";
						home-manager.extraSpecialArgs = { inherit inputs username host pkgs pkgsUnstable system; };
						home-manager.users.${username} = import ./hosts/${host}/home.nix;
					}
				];
			};
		};
	};
}