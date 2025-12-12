{ pkgs, pkgsUnstable, config, lib, ... }:

{
  home.packages = with pkgs; [
    ## ClI utils
    # Система
      kitty                                         # Терминал
      ghostty                                       # Терминал
      fastfetch                                     # Карточка ОС
      btop                                          # TUI мониторинг системы
      s-tui                                         # TUI стресс тест системы
      chezmoi                                       # Менеджер dotfiles
      
    # Git
      lazygit                                       # TUI для работы с Git
      gitui                                         # TUI для работы с Git
      serie                                         # TUI для отображения Git Graph
    
    # Docker
      lazydocker                                    # TUI для управления контейнерами 
      oxker                                         # TUI для управления контейнерами
    
    # БД / Журналы / SSH
      lazyjournal                                   # TUI для просмотра Linux журнала 
      lazysql                                       # TUI для работы с СУБД (Postgres, MySQL)
      rainfrog                                      # TUI для работы с Postgres
      lazyssh                                       # TUI для работы с SSH подключениями 
      go-task                                       # Менеджер системных задач
      
    # Tasks
      pom                                           # CLI таймер
      dooit                                         # TUI менеджер задач
      calcurse                                      # TUI календарь со списком задач  
      calcure                                       # TUI календарь
      
    # Дашборд / Разное
      wtfutil                                       # TUI дашборд 
      tldr                                          # Современная замена man
      navi                                          # Интерактивные шпаргалки по командам  
    
    # Media
      gtt                                           # TUI переводчик
      tdf                                           # TUI просмотр PDF
      papers                                        # Красивый просмотр PDF
      termusic                                      # TUI музыкальный плеер 
      swayimg                                       # TUI просмотрщик изображений 
      glow                                          # TUI Markdown редактор
      codesnap                                      # Создание скриншотов кода
      asciinema                                     # Создание записей терминала
      gpu-screen-recorder                           # Создание записей экрана
      
    # Сеть и интернет
      xh                                            # HTTP-клиент нового поколения
      httpie                                        # Удобный HTTP клиент
      posting                                       # TUI Rest API клиент
      oha                                           # TUI нагрузочное тестирование
      sniffnet                                      # TUI трафик сети
      trippy                                        # TUI диагностика сети
      gping                                         # Ping с графиком
      bluetui                                       # TUI для работы с Bluetooth 
      impala                                        # TUI для работы с WiFi
                
    # Файловая система
      eza                                           # Улучшенный ls — с иконками, цветами и деревом
      fd                                            # Улучшенный find — в десятки раз быстрее и проще
      fzf                                           # Нечёткий поиск по файлам, истории, процессам и всему подряд
      ripgrep                                       # Улучшенный grep — молниеносный поиск по тексту
      zoxide                                        # Улучшенный cd — запоминает папки и прыгает по ним командой z
      duf                                           # Вывод информации о диске
      dua                                           # TUI для очистки диска
      tokei                                         # Статистика по проектам (строки, языки и тд)
    
    # Остальное
      zellij                                        # TUI мультиплексор
      jq                                            # Мощный процессор JSON прямо в терминале
      fx                                            # TUI для работы с JSON
      bat                                           # Улучшенный cat — с подсветкой синтаксиса и номерами строк
      starship                                      # Красивый и сверхбыстрый prompt для терминала
      atuin                                         # Умная история команд с поиском и синхронизацией
      delta                                         # Улучшенный git diff — с подсветкой, side-by-side и навигацией
      trash-cli                                     # Безопасный rm — удаляет в корзину с возможностью восстановления
      procs                                         # Улучшенный ps — красивый и информативный вывод процессов
      zsh-fzf-tab                                   # Замена стандартного Tab-комплита на fzf-подсказки
      hyperfine                                     # Тест скорости команд
    
    # Приколюхи
      wthrr                                         # TUI погода
      clock-rs                                      # TUI вывод времени
      silicon                                       # Красивые скриншоты кода
      terminal-toys                                 # TUI вывод экрана ожидания
      pipes                                         # TUI вывод экрана ожидания
      astroterm                                     # TUI вывод звездной галактики
      smassh                                        # TUI аналог MonkeyType     
      ttyper                                        # TUI аналог MonkeyType
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = "${config.home.homeDirectory}/.zshrc";

    history = {
      expireDuplicatesFirst = true;
      ignoreSpace = true;
      path = "${config.xdg.cacheHome}/zsh/history";
      save = 100000;
      size = 100000;
    };

    enableCompletion = true;  
    syntaxHighlighting = { enable = true; };

    plugins = [
      { name = "fzf-tab"; src = pkgs.zsh-fzf-tab; }
      { name = "autosuggestions";  src = pkgs.zsh-autosuggestions; }
    ];

    shellAliases = {
      # Перемещение по директориям и работа с ними
      ls        = "eza --icons --group-directories-first --color=always";
      ll        = "eza -lh --icons --group-directories-first --color=always";
      la        = "eza -lah --icons --group-directories-first --color=always";
      lt        = "eza --tree --level=3 --icons";
      cd        = "z";
      cls       = "clear";
      c         = "clear";

      # Работа с файлами
      cat       = "bat --style=plain";
      rm        = "trash-put";
      grep      = "rg";
      find      = "fd";
      ps        = "procs";
      y         = "yazi";
      df        = "duf";
      du        = "dua i";

      
      # Lazy
      lzj       = "lazyjournal";
      lzh       = "lazyssh";
      lzs       = "lazysql";
      lzf       = "rainfrog";
      lzd       = "lazydocker";
      lzg       = "gitui";
      
      # Утилиты
      toy       = "pipes.sh -p 4 -t 3 -c 8 -r 0";
      trans     = "gtt -src English -src Russian";

      # git
      gtu       = "gitui";
      gts       = "serie";
      gti       = "git init";
      gta       = "git add";
      gtc       = "git commit";
      gtp       = "git push";
      gtl       = "git pull";
      gts       = "git status";
      
      # Сеть и интернет
      http      = "xh -F -j -f";
      hp        = "httpie";
      hpp       = "httpie-desktop";
      wf        = "impala";
      bl        = "bluetui";
      ping      = "gping"; 
      
      # Прочиe сокращения
      office    = "onlyoffice-desktopeditors";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 100 ''
        eval "$(starship init zsh)"
        eval "$(atuin init zsh --disable-up-arrow)"
        eval "$(zoxide init zsh)"
      '')

      (lib.mkOrder 550 ''
        # Клавиши
        bindkey "^[[1;5C" forward-word          # Ctrl+Right
        bindkey "^[[1;5D" backward-word         # Ctrl+Left
        bindkey '^ ' autosuggest-accept         # Ctrl+Space = принять подсказку
      '')

      (lib.mkOrder 600 ''
        # Автоподсказки — теперь точно работают
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70,bold"

        # Fastfetch при старте
        [[ -f ${config.xdg.configHome}/fastfetch/config-compact.jsonc ]] &&
          fastfetch -c ${config.xdg.configHome}/fastfetch/config-compact.jsonc

        # Delta — красивый diff навсегда
        command -v delta &>/dev/null && {
          git config --global core.pager "delta"
          git config --global interactive.diffFilter "delta --color-only"
          git config --global delta.navigate true
          git config --global delta.side-by-side false
        }
      '')
    ];
  };

  # ────────────────────── Starship ──────────────────────
  programs.starship = {
    enable = true;
    settings = { };
  };

  # ────────────────────── Atuin ──────────────────────
  programs.atuin = {
    enable = true;
    settings = {
      update_check = false;
      style = "compact";
      inline_height = 20;
      # enter_accept = "enter";
      search_mode = "prefix";
      filter_mode = "global";
    };
  };

  # ────────────────────── Zoxide ──────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;  
  };
}