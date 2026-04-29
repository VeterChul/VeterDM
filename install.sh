#!/bin/bash

sudo chmod 750 -R VeterDM

set -e  # прерывать при ошибке

# Цветной вывод
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Установка кастомного greeter (CRT Greeter) ===${NC}"

# 1. Установка пакетов
echo "Установка greetd, cage, seatd, python-prompt-toolkit..."
sudo pacman -S --noconfirm greetd cage seatd python-prompt_toolkit mpg123

# 2. Создание пользователя greeter (если не существует)
if ! id -u greeter >/dev/null 2>&1; then
    echo "Создание пользователя greeter..."
    sudo useradd -r -M -G video,seat greeter
else
    echo "Пользователь greeter уже существует, добавляем в группы video,seat..."
    sudo usermod -a -G video,seat greeter
fi

# 3. Создание изолированной HOME для greeter
echo "Создание /var/lib/crt-greeter..."
sudo mkdir -p /var/lib/crt-greeter/.config
sudo chown -R greeter:greeter /var/lib/crt-greeter
sudo chmod 750 /var/lib/crt-greeter

# 4. Создание симлинков (предполагается, что репозиторий клонирован в ~/VeterDM)
REPO_DIR="$HOME/.myconfig/VeterDM"   # измените, если путь другой
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${RED}Ошибка: репозиторий не найден в $REPO_DIR${NC}"
    exit 1
fi


echo "Копирование файлов из $REPO_DIR в /opt/VeterDM"
echo "Создание симлинков из $REPO_DIR в системные каталоги..."

sudo mkdir /opt/VeterDM/
sudo cp -r $REPO_DIR/. /opt/VeterDM/
sudo chown -R greeter:greeter /opt/VeterDM
sudo chmod 755 -R /opt/VeterDM/

sudo rm -rf $REPO_DIR

/opt/VeterDM/create-link.sh

# 5. Права на скрипты
sudo chmod +x /usr/local/bin/crt-greeter.py
sudo chmod +x /usr/local/bin/start-greeter.sh
sudo chmod +x /usr/local/bin/cool-retro-term-castom

# --- Дополнительные настройки для аутентификации и доступа ---
echo "Настройка прав для аутентификации..."
sudo chmod u+s /usr/bin/unix_chkpwd 2>/dev/null || true
if getent group shadow >/dev/null; then
    sudo usermod -a -G shadow greeter
fi

echo "Настройка прав на /var/lib/crt-greeter..."
sudo chown -R greeter:greeter /var/lib/crt-greeter
sudo chmod 750 /var/lib/crt-greeter

# 6. Настройка PAM для greetd (если файла нет – создаём)
if [ ! -f /etc/pam.d/greetd ]; then
    echo "Создание /etc/pam.d/greetd..."
    sudo tee /etc/pam.d/greetd > /dev/null <<EOF
#%PAM-1.0
auth        requisite   pam_nologin.so
auth        required    pam_unix.so    try_first_pass nullok
auth        optional    pam_permit.so
account     required    pam_unix.so
password    required    pam_deny.so
session     required    pam_unix.so
session     optional    pam_systemd.so
EOF
fi

# === Настройка звуковой подсистемы для greeter ===
echo "Настройка звука..."

# 1. Добавляем greeter в группу audio
sudo usermod -aG audio greeter

# 2. Включаем постоянную пользовательскую сессию (linger) для greeter
#    Это гарантирует, что пользовательский менеджер systemd для 'greeter' будет запущен
#    при загрузке системы и продолжит работу после выхода из "сессии".
sudo loginctl enable-linger greeter
echo "linger включён для greeter"

# 3. Устанавливаем необходимые пакеты (если их нет)
sudo pacman -S --noconfirm pipewire wireplumber pipewire-pulse alsa-utils

# 4. Включаем пользовательские службы PipeWire и WirePlumber для greeter
#    Выполняем команды от имени пользователя 'greeter'
#    Включаем .socket units, так как они используют сокет-активацию, что является
#    предпочтительным способом запуска PipeWire.
sudo -u greeter systemctl --user enable pipewire.socket
sudo -u greeter systemctl --user enable pipewire-pulse.socket
sudo -u greeter systemctl --user enable wireplumber

#    Запускаем их, чтобы не ждать перезагрузки.
echo "Запуск служб звука..."
sudo -u greeter systemctl --user start pipewire.socket
sudo -u greeter systemctl --user start pipewire-pulse.socket
sudo -u greeter systemctl --user start wireplumber

# 5. Устанавливаем максимальную громкость на уровне ALSA
amixer sset Master 100% unmute 2>/dev/null || true
amixer sset PCM 100% unmute 2>/dev/null || true
sudo alsactl store 2>/dev/null || true
echo "Громкость установлена на максимум"

# 6. Проверяем статус, чтобы убедиться, что сервисы активны
echo "Проверка статуса звуковых служб:"
sudo -u greeter systemctl --user status pipewire pipewire-pulse wireplumber --no-pager

# 5. Устанавливаем максимальную громкость на уровне ALSA
amixer sset Master 100% unmute 2>/dev/null || true
amixer sset PCM 100% unmute 2>/dev/null || true
sudo alsactl store 2>/dev/null || true
echo "Громкость установлена на максимум"

# # 7. Отключение старого DM и включение greetd
# echo "Переключение на greetd..."
# sudo systemctl stop sddm 2>/dev/null || true
# sudo systemctl disable sddm 2>/dev/null || true
# sudo rm -f /etc/systemd/system/display-manager.service
# sudo systemctl enable --now greetd.service

echo -e "${GREEN}Установка завершена! Перезагрузитесь или переключитесь на TTY1 (Ctrl+Alt+F1), чтобы увидеть экран входа.${NC}"