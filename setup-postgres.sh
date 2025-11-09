#!/bin/bash

# Скрипт для первоначальной настройки PostgreSQL

echo "Настройка PostgreSQL для CRM..."
echo ""

# Проверка установки PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL не установлен!"
    echo ""
    echo "Для установки выполните:"
    echo "Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "Fedora: sudo dnf install postgresql postgresql-server"
    echo "macOS: brew install postgresql"
    exit 1
fi

# Запуск PostgreSQL если не запущен
echo "Проверка статуса PostgreSQL..."
if ! pg_isready -q 2>/dev/null; then
    echo "PostgreSQL не запущен. Попытка запуска..."
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start postgresql
    fi
    
    sleep 2
    
    if ! pg_isready -q 2>/dev/null; then
        echo "Не удалось запустить PostgreSQL"
        exit 1
    fi
fi

echo "PostgreSQL запущен"
echo ""
echo "Теперь запустите ./start.sh для запуска приложения"