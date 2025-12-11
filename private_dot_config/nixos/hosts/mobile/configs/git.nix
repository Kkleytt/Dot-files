{ lib, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "Kkleytt";
          email = "kkleytt@gmail.com";
        };

        url."git@github.com:" = {
          insteadOf = "https://github.com/";
        };

        push.autoSetupRemote = true;

        credential.helper = "cache --timeout=3600";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        user = "kkleytt";
        identityFile = "~/.ssh/id_ed25519";
      };
      matchBlocks."github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # Автоматическая генерация ключа при активации
  home.activation.generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f ~/.ssh/id_ed25519 ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "kkleytt@nixos"
      echo
      echo "👉 Публичный ключ:"
      cat ~/.ssh/id_ed25519.pub
      echo
      echo "Добавьте его в GitHub: https://github.com/settings/keys"
    fi
  '';
}
