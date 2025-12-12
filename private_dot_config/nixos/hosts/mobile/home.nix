{ pkgs, inputs, config, ... }: {
  home.username = "kkleytt";
  home.homeDirectory = "/home/kkleytt";
  home.stateVersion = "25.11";

  # Приложения (Apps)
  home.packages = (with pkgs; [
    ## Caelestia
      inputs.caelestia-shell.packages.${stdenv.hostPlatform.system}.default
      inputs.caelestia-cli.packages.${stdenv.hostPlatform.system}.default

    ## Programming Language & Tools
      #### Virtualization  
        docker                                    # Платформа контейнеризации
        docker-compose                            # Управление мультиконтейнерными приложениями
        kubernetes                                # Оркестрирование множеством контейнеров на разных хост-машинах

      #### Python
        python314                                 # Глобальный Python интерпретатор
        uv                                        # Сверхбыстрый заменитель pip, virtualenv, poetry
        mypy                                      # Статический анализатор типов
        ruff                                      # Быстрый линтер и автоисправитель на Rust
        ty                                        # Статический анализатор типов
        
      #### LSP
        nil                                       # Nix
        vscode-css-languageserver                 # CSS
        vscode-json-languageserver                # JSON
        bash-language-server                      # Bash
        yaml-language-server                      # YAML
        rust-analyzer                             # Rust
        hyprlang                                  # Hyprland

      #### Rust
        rustc                                     # Компилятор языка Rust.
        cargo                                     # Менеджер пакетов и сборки для Rust.

      #### Javascript
        nodejs_24                                 # Интерпретатор Node.js версии 24 (актуальная LTS на 2025)
        pnpm                                      # Быстрый и экономичный менеджер пакетов для Node.js
        typescript                                # Компилятор и типизация для TypeScript
        eslint                                    # Линтер для JavaScript/TypeScript
      
      #### C / C++
        gcc                                       # Компилятор GNU для C/C++.
        # clang                                     # Альтернативный компилятор от LLVM — быстрее, лучше ошибки.

      #### Editors
        neovim                                    # Улучшенный редактор кода NeoVim
        zed-editor                                # Быстрый аналог VsCode
        vscode                                    # Классический VsCode
        # vscodium                                  # VsCode без телеметрии и слежки
        # jetbrains.pycharm-community               # Бесплатная версия Pycharm
        # sublimetext4                              # Быстрый редактор кода
        # arduino-ide                               # IDE для работы с Arduino
        # windsurf                                  # IDE для работы совместно с агентом
        # code-cursor                               # IDE для работы совместно с агентом

      #### Utils
        postman                                   # Авто-тесты для API
        devtoolbox                                # Дополнительные функции для программиста
        # qwen-code                                 # AI агент в режиме консоли Qwen [не работает так как находимся на стабильной ветке]
        # termius                                   # Gui SSH + Sftp клиент
        # turtle                                    # Gui для работы с Git
        # textpieces                                # Дополнительные функции для программиста
        # tiny-rdm                                  # Gui для работы с Redis
        # warehouse                                 # Менеджер пакетов Flatpak

      #### Other programming tools
        pre-commit                                # Фреймворк для запуска проверок перед коммитом
        envsubst                                  # Работа с перемнными на GO
        # zeal                                      # Документация для программистов
      
    ## Необязательные приложения
      rofi-bluetooth                              # Управление Bluetooth через Rofi
      rofi-network-manager                        # Управление интернетом через Rofi

    ## Browsers
      # brave                                       # Браузер Brave
      # vivaldi                                     # Браузер Vivaldi
      # qutebrowser                                 # Браузер для управления без мышки
      # firefox                                     # Браузер Firefox

    ## Office
      onlyoffice-desktopeditors                   # Аналог Microsoft Office
      thunderbird                                 # Mail клиент

    ## Notepads & Read apps
      obsidian                                    # Полноценный Markdown редактор
      keypunch                                    # Аналог monkeytype
      # anytype                                     # Аналог Notion
      # apostrophe                                  # Красивый Markdown редактор
      # appflowy                                    # Аналог Notion
      # folio                                       # Простой Markdown редактор
      # foliate                                     # Читалка книг

    ## ToDo & Time control apps
      pomodoro-gtk                                  # GUI таймер
      super-productivity                            # Полноценные ToDo заметки
      # morgen                                      # Все в одном: Календарь, Задачи, Заметки, Напоминания
      # errands                                     # Todo заметки
      # planify                                     # Красивые ToDo заметки
      # iotas                                       # Красивые ToDo заметки
      # kuro                                        # Неофициальный клиент Microsoft ToDo

    ## File system & Backups utils
      peazip                                      # Минималистичный архиватор
      pika-backup                                 # Бекап системы
      fragments                                   # Торрент клиент
      syncthing                                   # P2P синхронизация файлов без серверов
      # deja-dup                                    # Бекап файлов

    ## Standart apps in other shell
      rofi                                        # Универсальный лаунчер
      baobab                                      # Просмотр использования диска
      gnome-secrets                               # Менеджер паролей
      gnome-disk-utility                          # Управление дисками
      gnome-clocks                                # Часы, Таймер, Секундомер
      gnome-calculator                            # Калькулятор
      dialect                                     # Переводчик
      # gnome-weather                               # Погода
      # sticky-notes                                # Быстрые заметки
      # gnome-sound-recorder                        # Запись аудио
      # gnome-text-editor                           # Текстовый редактор
      # gnome-boxes                                 # Управление виртуальными машинами
      # turnon                                      # Wake-On-Lan приложение
      # gnome-frog                                  # Получение текста из скриншота
      # mission-center                              # Просмотр нагрузки на ПК
      # crow-translate                              # Переводчик
      # gnome-calendar                              # Календарь
      
    ## Games
      tetris                                        # TUI тетрис
      # bottles                                     # Система запуска exe программ на базе Wine
      # retroarch                                   # Менеджер ретро-игр
      # heroic                                      # Игровая платформа для Epic Games Store
      # cartridges                                  # Лаунчер для игр (Официальных)
    
    ## Social
      materialgram                                # Неофициальный клиент Telegram
      # legcord                                     # Неофициальный Discord клиент
      # rambox                                      # Менеджер соц-сетей
      # telegram-desktop                            # Официальный клиент Telegram
      # vesktop                                     # Неофициальный клеинт Discord
      # ferdium                                     # Менеджер соц-сетей
      # denaro                                      # Менеджер финансов
  
    ## WIKI: Стоит изучить данные утилиты в кратчайшие сроки и начать ими пользоваться для продуктивного использования системы
      # yazi                                        # Файловый менеджер
      # ripgrep                                     # Быстрый поиск текста в файлах 
      # atuin                                       # Расширенная история команд
      # zoxide                                      # Умный cd с запоминанием директорий
      # tldr                                        # Красивый вывод информации о команде (аналог man)
      # fd                                          # Быстрый поиск файлов (аналог find)
      # httpx                                       # Дружелюбная альтернатива curl для тестирования API
      # lazygit                                     # TUI для Git (коммиты, ветки, история)
      # lazydocker                                  # TUI для управления контейнерами
      # lazyjournal                                 # TUI для просмотра Linux журнала
      # lazyssh                                     # TUI для работы с SSH подключениями
      # lazysql                                     # TUI для работы с СУБД (Postgres, MySQL)
      # dooit                                       # TUI ToDo список задач
      # calcurse                                    # TUI календарь со списком задач
      # culcure                                     # TUI календарь со списком задач                                              
  ]); 
  
  imports = [
    ./configs/git.nix                   # Настройка Git и SSH ключей
    ./configs/terminal.nix              # Настройка терминала
    #./configs/user_configs.nix          # Настройка локальных конфигов пользователя
  ];
  
  xdg.userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    download = "${config.home.homeDirectory}/Downloads";
    documents = "${config.home.homeDirectory}/Documents";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
  };

}
