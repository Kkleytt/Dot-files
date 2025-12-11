{ config, pkgs, host, username, options, lib, inputs, ...}: 
let
  inherit (import ./variables.nix) keyboardLayout;

  sddm-theme = inputs.silentSDDM.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    theme = "catppuccin-macchiato";
  };
    
in {
  imports = [
    ./hardware.nix                            # Настройка аппаратной конфигурации
    ./packages-fonts.nix                      # Установка шрифтов и обязательных пакетов
    ./users.nix                               # Настройка пользователей
    ./unstable.nix                            # Нетсбильные пакеты
    ../../modules/amd-drivers.nix
    ../../modules/vm-guest-services.nix
    ../../modules/local-hardware-clock.nix
    # ../../modules/nvidia-drivers.nix
    # ../../modules/nvidia-prime-drivers.nix
    # ../../modules/intel-drivers.nix
  ];
  
  # Версия системы
  system.stateVersion = "25.11";

  # Настройка boot 
  boot = {
    kernelPackages = pkgs.linuxPackages_zen; # zen Kernel

    kernelParams = [
      "systemd.mask=systemd-vconsole-setup.service"
      "systemd.mask=dev-tpmrm0.device"
      "nowatchdog" 
      "modprobe.blacklist=sp5100_tco" # Наблюдатель AMD
      # "modprobe.blacklist=iTCO_wdt"   # Наблюдатель Intel
    ];
    
    initrd = { 
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
    };

    loader.systemd-boot.enable = true;
    loader.efi = {
      canTouchEfiVariables = true;
    };
    loader.timeout = 10; 
  
    # Создание /tmp как tmpfs
    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
    };
    
    # Параметры иконок для приложений
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
      };
    
    plymouth.enable = true;
  };

  # Драйвера
  drivers = {
    amdgpu.enable = true;
    # intel.enable = true;
    # nvidia.enable = false;
    # nvidia-prime = {
    #    enable = false;
    #      intelBusID = "";
    #      nvidiaBusID = "";
    # };
  };
  programs.nix-ld.enable = true;
  vm.guest-services.enable = false;
  local.hardware-clock.enable = false;

  # Настройки сетей
  networking = {
    networkmanager.enable = true;
    hostName = "${host}";
    timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
  }; 

  # Настройки региона
  services.automatic-timezoned.enable = true; # Часовой пояс на основе IP-адреса
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  environment.variables = {
    XDG_DESKTOP_DIR="$HOME/Desktop";
    XDG_DOWNLOAD_DIR="$HOME/Downloads";
    XDG_TEMPLATES_DIR="$HOME/Templates";
    XDG_PUBLICSHARE_DIR="$HOME/Public";
    XDG_DOCUMENTS_DIR="$HOME/Documents";
    XDG_MUSIC_DIR="$HOME/Music";
    XDG_PICTURES_DIR="$HOME/Pictures";
    XDG_VIDEOS_DIR="$HOME/Videos";
  };

  qt.enable = true;
  environment.systemPackages = [
    sddm-theme
    sddm-theme.test
  ];
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = sddm-theme.pname;
    wayland.enable = true;
    extraPackages = sddm-theme.propagatedBuildInputs;
    settings.General = {
      GreeterEnvironment = "QML2_IMPORT_PATH=${sddm-theme}/share/sddm/themes/${sddm-theme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard,QT_SCALE_FACTOR=2";
      InputMethod = "qtvirtualkeyboard";
    };
    settings.Keyboard = {
      Layouts = "us,ru";
      Options = "grp:alt_shift_toggle";
    };
  };


  # Сервисы для авто-загрузки
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "${keyboardLayout}";
        variant = "";
      };
    };

    power-profiles-daemon.enable = true;
    
    greetd = {
      enable = false;
      settings = {
        default_session = {
          user = username;
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland"; # start Hyprland with a TUI login manager
        };
      };
    };
    
    smartd = {
      enable = false;
      autodetect = true;
    };
    
    gvfs.enable = true;
    tumbler.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
	
    pulseaudio.enable = false;
    udev.enable = true;
    envfs.enable = true;
    dbus.enable = true;

    fstrim = {
      enable = true;
      interval = "weekly";
    };
  
    libinput.enable = true;
    rpcbind.enable = false;
    nfs.server.enable = false;
    openssh.enable = true;
    flatpak.enable = true;
    blueman.enable = true;

    # Включение функции подсветки компонентов
    #hardware.openrgb.enable = true;
    #hardware.openrgb.motherboard = "amd";

    fwupd.enable = true;
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
    
    ipp-usb.enable = true;
  };


  # zram
  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 30;
    swapDevices = 1;
    algorithm = "zstd";
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  #hardware.sane = {
  #  enable = true;
  #  extraBackends = [ pkgs.sane-airscan ];
  #  disabledDefaultBackends = [ "escl" ];
  #};

  # Bluetooth
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
  };

  # Настройки Polkit Менеджера
  security = { 
    rtkit.enable = false;
    soteria.enable = true;
    polkit.enable = true;
    polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
    })
  '';
  };
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  # Кэширование, оптимизация и очистка системы
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Виртуализация, Docker и Podman
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = false;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = false;
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
  };

  console.keyMap = "us";

  # For Electron apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.QML_IMPORT_PATH = "${pkgs.hyprland-qt-support}/lib/qt-6/qml";
}
