# Список всех скриптов для корректной работы системы

### Модуль Peripherals (Управление периферией, клавиатура, мышка, тачпад, сенсорный экран, wifi, bluetooth)
  ##### Поддерживаемые команды:
  - [x] keyboard `get` - Управление клавиатурой
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] layout `layoyt = [toggle, us, ru]`
    - [x] brightness
    - [x] get
  - [x] touchpad `get` - Управление тачпадом
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] get
  - [x] touchscreen `get` - Управление сенсорным экраном
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] get
  - [x] mouse `get` - Управление мышкой
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] get
  - [x] bluetooth `get` - Управление Bluetooth
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] get
  - [x] wifi `get` - Управление Wi-Fi
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] get
  - [x] all `get` - Управление всеми устройствами сразу
    - [x] enable
    - [x] get
    - [x] timer `time = 60`

### Модуль Media (Управление медиа инструментами, плеер, громкость, яркость, авиа-режим, скриншоты)
  ##### Поддерживаемые команды:
  - [x] player `toggle` - Управление плеером
    - [x] play
    - [x] pause
    - [x] toggle
    - [x] stop 
    - [x] next
    - [x] previous 
  - [x] speaker - Управление громкостью динамиков
    - [x] get
    - [x] get-icon
    - [x] set `value = `
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] up `step = 5`
    - [x] down `step = 5`
  - [x] microphone - Управление громкостью микрофона
    - [x] get
    - [x] get-icon
    - [x] set `value = `
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] up `step = 5`
    - [x] down `step = 5`
  - [x] brightness `get` - Управление яркостью экрана
    - [x] get
    - [x] set `value = `
    - [x] up `step = 5`
    - [x] down `step = 5`
    - [x] cycle `steps = 5`
  - [x] airplane `get` - Управление режимом полета
    - [x] get
    - [x] enable
    - [x] disable
    - [x] toggle
  - [x] screenshot - Создание скриншотов
    - [x] screen `edit = True`
    - [x] window `edit = True`
    - [x] area `edit = True`
    - [x] fast
    - [x] freeze
  - [x] screenrecord - Запись экрана
    - [x] start/stop `{-r | -s}`
    - [x] play/pause

### Модуль Hyprland (Управление свойствами окон, Скрытый режим, скрытое пространство, управление opacity, игровой режим)
  ##### Поддерживаемые команды:
  - [x] shadow - Скрытный режим
    - [x] toggle
    - [x] app
      - [x] terminal
      - [x] browser
      - [x] obsidian
      - [x] password
      - [x] vscode
  - [x] decoration - Управление визальным видом
    - [x] opacity (Прозрачность)
    - [x] blur (Размытие)
    - [x] layout (Правила размещения окон)
    - [x] game_mode (Игровой режим)

### Модуль Caelestia (Управление Caelestia shell, управление панелями, запись экрана, выбор тем иконок и гифок, наблюдатель)
  ##### Поддерживаемыее команды:
  - [x] lock - управление блокировкой системой
    - [x] lock
    - [x] unlock
    - [x] islocked
  - [x] watcher - Наблюдатель за темой Caelestia и преобразование его в темы для других приложений
    - [x] variables
    - [x] themes
    - [x] template
    - [x] wallpapers
    - [x] restart
  - [x] shell - Запуск облочки
    - [x] enable
    - [x] disable
    - [x] toggle
    - [x] restart
  - [x] panels - Работа с панелями
    - [x] launher
    - [x] dashboard
    - [x] sidebar
    - [x] session
    - [x] bar
      - [x] hide
      - [x] unhide
      - [x] toggle
  - [ ] themes - Работа с темами оболочки
    - [ ] icons
      - [ ] select
      - [ ] save
    - [ ] gifs
      - [ ] select
      - [ ] save
  - [x] services - Работа с встроенными сервисами
    - [x] clipboard
    - [x] emoji

### Модуль Rofi (Вывод мини программ для работы с ОС)
  ##### Поддерживаемые параметры:
  - [x] wallpapers `path = $HOME/Pictures/Wallpapers`
  - [x] radio 
  - [x] clipboard  
  - [x] emoji
  - [x] search `engine = google`
  - [x] keyhints `path = $HOME/.config/hypr/UserScrpts/keyhint`

### Модуль Notifications (Модуль для единой отправки уведомлений)
  ##### Поддерживаемые параметры
  - [ ] enable
  - [ ] disable
  - [ ] toggle
  - [ ] sound `enable`
    - [ ] enable
    - [ ] disable
    - [ ] toggle

### Модуль VarManager (Управление Hyprland перемеенными, получение из конфига, адаптация в JSON, работа с переменными)
  ##### Поддерживаемые параметры
  - [x] load `path = $HOME/.config/hypr/UserConfigs/Variables.conf`
  - [x] get `variable = `
  - [x] set `variable = ` `value = `
  - [ ] get_type `variable = `
  - [ ] backup `path = $HOME/.config/hypr/UserConfigs/Variables.conf.bak`


### Дополнительные модули для работы CLI
  - pamixer                     - Управление громкостью устройств (дианмик/наушники/микрофоны)
  - brightnessctl               - Управление подсветкой устройств (экрана, клавиатуры)
  - caelestia                   - Оболочка
  - playerctl                   - Управление плеером Mpris
  - rfkill                      - Программное управление Bluetooth, Wi-Fi, Wlan
  - satty                       - Анотация скриншотов
  - wl-copy                     - Служба буфера обмена
  - grim                        - Программа для создания скриншота
  - rofi                        - Утилита для создания мини-приложений
  - hyprland                    - Менеджер оконо


### Перевод всех скриптов в формат CLI подлкючаемых Python библиотек
  - [ ] Media
    - [x] brightness
    - [x] microphone
    - [x] speaker
    - [ ] player
    - [x] airplane
    - [x] screenrecord
    - [x] screenshot
  - [x] Peripherals
    - [x] keyboard
    - [x] mouse
    - [x] touchpad
    - [x] touchscreen
    - [x] wifi
    - [x] bluetooth
    - [x] clean
  - [ ] hyprland
    - [x] decorate
    - [x] hyprapps
    - [x] idle
    - [ ] kill
    - [x] shadow
  - [ ] caelestia
    - [ ] init
    - [x] lock
    - [x] panels
    - [x] rofi
    - [x] shell
    - [ ] watcher