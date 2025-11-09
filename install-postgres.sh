#!/bin/bash

# Скрипт для установки PostgreSQL

echo "Установка PostgreSQL..."
echo ""

# Определение дистрибутива
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
fi

# Установка для Ubuntu/Debian
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    echo "Обнаружен $OS. Установка PostgreSQL..."
    
    # Обновление репозиториев
    sudo apt-get update
    
    # Установка PostgreSQL
    sudo apt-get install -y postgresql postgresql-contrib
    
    # Запуск и включение автозапуска
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    echo "PostgreSQL установлен"
    
# Установка для Fedora/RedHat/CentOS
elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
    echo "Обнаружен $OS. Установка PostgreSQL..."
    
    # Установка PostgreSQL
    sudo dnf install -y postgresql postgresql-server postgresql-contrib
    
    # Инициализация базы данных
    sudo postgresql-setup --initdb
    
    # Запуск и включение автозапуска
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    echo "PostgreSQL установлен"
    
else
    echo "   Не удалось определить дистрибутив Linux"
    echo "   Установите PostgreSQL вручную:"
    echo "   Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "   Fedora: sudo dnf install postgresql postgresql-server"
    echo "   Arch: sudo pacman -S postgresql"
    exit 1
fi

# Настройка пользователя postgres
echo ""
echo "Настройка пользователя postgres..."

# Установка пароля для пользователя postgres
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"

# Настройка аутентификации
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_MAJOR=$(echo $PG_VERSION | cut -d. -f1)

if [ -z "$PG_MAJOR" ]; then
    PG_MAJOR=15  # По умолчанию
fi

# Путь к конфигурации
PG_CONFIG_DIR="/etc/postgresql/$PG_MAJOR/main"
if [ ! -d "$PG_CONFIG_DIR" ]; then
    # Для систем где PostgreSQL установлен в другом месте
    PG_CONFIG_DIR=$(sudo -u postgres psql -t -c "SHOW config_file;" | xargs dirname 2>/dev/null)
fi

if [ -d "$PG_CONFIG_DIR" ]; then
    echo "   Обновление конфигурации PostgreSQL..."
    
    # Резервная копия
    sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup"
    
    # Изменение метода аутентификации на md5 для локальных подключений
    sudo sed -i 's/local   all             postgres                                peer/local   all             postgres                                md5/' "$PG_CONFIG_DIR/pg_hba.conf"
    sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' "$PG_CONFIG_DIR/pg_hba.conf"
    
    # Перезапуск PostgreSQL
    sudo systemctl restart postgresql
fi

echo ""
echo "PostgreSQL установлен и настроен"
echo ""
echo "Теперь запустите ./start.sh для запуска приложения"