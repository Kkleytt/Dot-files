# Получение PID активного окна
active_pid=$(hyprctl activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)

# Завершение процесса
kill $active_pid