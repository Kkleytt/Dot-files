{ pkgs, ...}:

{
  environment.systemPackages = (with pkgs; [
    ## 📦 Базовые системные утилиты
      btrfs-progs                                 # Утилиты для работы с Btrfs
      cpufrequtils                                # Управление частотой CPU
      findutils                                   # Find, xargs и др.
      glib                                        # Для работы gsettings
      gsettings-qt                                # Qt‑обёртка для gsettings
      git                                         # Контроль версий Git
      killall                                     # Завершение процессов по имени
      libappindicator                             # Иконки в системном трее
      libnotify                                   # Уведомления
      openssl                                     # Криптография (требуется для Rainbow borders)
      openssh                                     # Поддержка SSH ключей
      pciutils                                    # Информация об устройствах PCI
      xdg-user-dirs                               # Стандартные пользовательские каталоги
      xdg-utils                                   # Утилиты XDG
      unzip                                       # CLI архиватор
      ntfs3g                                      # Поддержка NTFS файловых систем
      exfat									                      # Поддержка ExFat файловых системы
      bc                                          # Компилятор для калькулятора 
      inotify-tools                               # Наблюдатель за файлами
      curl                                        # Универсальная утилита для HTTP-запросов
      wget                                        # Классическая утилита для скачивания файлов и сайтов
      mediainfo                                   # Получение мета данных файлов
      
    # CLI утилиты
      bat                                         # Улучшенный cat — с подсветкой синтаксиса и номерами строк
      eza                                         # Улучшенный ls — с иконками, цветами и деревом
      fd                                          # Улучшенный find — в десятки раз быстрее и проще
      fzf                                         # Нечёткий поиск по файлам, истории, процессам и всему подряд
      jq                                          # Мощный процессор JSON прямо в терминале
      duf                                         # Улучшенный df — красивая таблица использования дисков


    ## 🎨 Внешний вид и темы
      gtk-engine-murrine                          # Темы GTK2-GTK3
      libsForQt5.qtstyleplugin-kvantum            # Поддержка QT стилей
      kdePackages.qtstyleplugin-kvantum           # Поддержка QT стилей
      libsForQt5.qt5ct                            # Настройка Qt5 тем
      kdePackages.qt6ct                           # Настройка Qt6 тем
      kdePackages.qtwayland                       # Qt поддержка Wayland
      nwg-look                                    # утилита оформления
      pywal16                                     # Выборка цветов из обоев
      
    # Просмотрщики (Audio/Video/Pictures)
      yazi                                        # Файловый менеджер
      papers                                      # Красивый просмотр PDF
      loupe                                       # Красивый просмотрщик фото
      feh                                         # Просмотрщик фото + Сортировщик
      musicpod                                    # Музыкальный плеер + Радио + Подкасты
      mpv                                         # Базовый медиа плеер
      clapper                                     # Красивый медиа плеер
    
    # Интернет и Bluetooth
      networkmanagerapplet                        # GUI для NetworkManager
      bluez                                       # Bluetooth стэк
      bluez-tools                                 # Дополнительные функции Bluetooth

    ## 🎧 Аудио и мультимедиа
      pamixer                                     # Управление громкостью (CLI)
      pavucontrol                                 # Управление PulseAudio/PipeWire
      pulseaudio                                  # Оригинальный PulseAudio
      playerctl                                   # Управление медиаплеерами
      yt-dlp                                      # Загрузка видео/аудио
      brightnessctl                               # Управление яркостью экрана


    ## 🖼️ Графика и скриншоты
      imagemagick                                 # CLI обработка изображений
      satty                                       # Аннотации и правка скриншотов
      gradia                                      # Аннотация скриншотов и их создание
      

    ## 🧩 Hyprland и Wayland
      hyprpaper                                   # Установщик обоев для рабочего стола
      hyprpicker                                  # Получение цвета с экрана
      hyprshot                                    # Создание скриншотов
      hyprsunset                                  # Изменение цвета экрана в зависимости от времени суток
      hypridle                                    # Блокировка и управление сном
      hyprland-qt-support                         # Поддержка QT тем
      cliphist                                    # История буфера обмена
      power-profiles-daemon                       # Настройка профиля питания
      nwg-displays                                # Настройка дисплеев
      wl-clipboard                                # Буфер обмена Wayland
      yad                                         # GUI-диалоги
      libsecret                                   # Хранилище паролей для безопасности приложений
      wev                                         # Проверка названий клавиш клавиатуры

    ## 🧙 Разное
      polkit_gnome                                # Агент аутентификации  
      flatpak                                     # Менеджер пакетов Flatpak
      beekeeper-studio  
  ]);


  # Установка шрифтов
  fonts = {
    packages = with pkgs; [
      noto-fonts
      fira-code
      noto-fonts-cjk-sans
      jetbrains-mono
      font-awesome
      terminus_font
      victor-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.fantasque-sans-mono
    ];
  };

  # Настройка программ
  programs = {
    # Настройки Hyprland
    hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    dconf.enable = true;
    seahorse.enable = true;
    mtr.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    nm-applet.indicator = true;
    virt-manager.enable = false;
    fuse.userAllowOther = true;


    # Настройка проводников
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman ];
    };
  };

  # Extra Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.common.default = [ "gtk" ];
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  services = {
    # Установка Flatpak пакетов
    flatpak = {
      enable = true;
      packages = [
        "app.zen_browser.zen"                       # Браузер Zen на базе Firefox 
        # "io.beekeeperstudio.Studio"                 # Управление SQL Базами Данных 
      ];
    };

    # Настройка Jupyter
    jupyter = {
      enable = true;

      # Generate password in terminal - `python3 -c "from jupyter_server.auth import passwd; print(passwd())"`
      # This password is `Fedoskin010220053666!`
      password = "argon2:$argon2id$v=19$m=10240,t=10,p=8$S0ykdta+ysLy5ZrTwHJx8g$01/XNcbuu+APIYo7PMwujdZ+bxTfgsQUjXXgVJxoyrw";
      
      # Connect with url - `http://127.0.0.1:8888`
      ip = "localhost";
      port = 8888;

      # Additional kernels to use (additional libraries)
      kernels = let
        basePackages = ps: with ps; [ ipykernel jupyterlab orjson httpx pydantic redis asyncpg fastapi sqlalchemy loguru ];

        mk = name: display: extra: {
          inherit display;
          language = "python";
          argv = let
            env = pkgs.python313.withPackages (ps: (basePackages ps) ++ (extra ps));
          in [
            "${env.interpreter}"
            "-m" "ipykernel_launcher"
            "-f" "{connection_file}"
          ];
        };
      in {
        base  = mk "base"   "Default Python"                    (ps: []);
        study = mk "study"  "Study Python"                      (ps: with ps; [ aio-pika aiokafka celery asyncmy ]);
        ml    = mk "ml"     "Machine Learning Python"           (ps: with ps; [ torch torchvision torchaudio scikit-learn numpy pandas matplotlib seaborn plotly ]);
        web   = mk "web"    "Python for web"                    (ps: with ps; [ aiokafka pyjwt asyncmy uvicorn aiomysql alembic ]);
        cli   = mk "cli"    "CLI / TUI Python"                  (ps: with ps; [ typer rich textual colorama ]);
      };
    };
  };
}
