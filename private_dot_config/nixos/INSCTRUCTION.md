Инструкция по созданию билда NixOS на любой машине

1. Скачайте данный репозиторий к себе на пк по пути ~/nixos/
2. Замените файл hardware-configuration.nix на ваш файл по пути /etc/nixos/
3. Из настроек проекта вы можете поменять:
    - Имя пк
    - Имя пользователя
    - Пароль пользователя
    - Настройки git
    - Устанавливаемые пакеты


4. Как подключить контроллер DualSense по Bluetooth
    - Сначала подключите контроллер по USB чтобы система скачала драйвера
    - Потом зайдите в Blueman-Manager и создайте подключение к контроллеру
    - Скопируйте MAC адрес контроллера
    - Отключитесь от контроллера
    - Зайдите в терминал и поочередно введите эти команды
        - bluetoothctl power on
        - bluetoothctl agent KeyboardOnly
        - bluetoothctl default-agent
        - bluetoothctl pairable on
        - bluetoothctl discoverable on
        - bluetoothctl scan on
    - Заново включаем контроллер сочетанием клавиш (Source + Playstation)
        - bluetoothctl pair $MAC
        - bluetoothctl trust $MAC
        - bluetoothctl connect $MAC
    