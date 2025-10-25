#!/usr/bin/env bash

# Убиваем все запущенные процессы caelestia-shell
pkill -f caelestia
caelestia-shell kill

# Небольшая пауза, чтобы процесс точно завершился (опционально)
sleep 1

# Запускаем caelestia-shell в фоне
caelestia-shell &