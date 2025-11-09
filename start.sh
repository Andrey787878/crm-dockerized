#!/bin/bash

# Скрипт для запуска CRM-приложения локально

echo "Запуск приложения..."
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка установки PostgreSQL
if ! command -v psql &> /dev/null; then
    echo -e "${RED}PostgreSQL не установлен${NC}"
    echo "   Установите PostgreSQL командой:"
    echo "   sudo apt-get install postgresql postgresql-contrib"
    echo ""
    echo "   Или для других систем:"
    echo "   macOS: brew install postgresql"
    echo "   Fedora: sudo dnf install postgresql postgresql-server"
    exit 1
fi

# Проверка установки Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js не установлен${NC}"
    echo "   Установите Node.js с https://nodejs.org/"
    exit 1
fi

# Рекомендуемая версия Node.js
REQUIRED_NODE_VERSION="18"
CURRENT_NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)

echo -e "${GREEN}Проверка версии Node.js...${NC}"
echo "   Текущая версия: v$(node -v | cut -d'v' -f2)"

# Проверка и переключение версии Node.js через nvm если доступно
if command -v nvm &> /dev/null || [ -s "$NVM_DIR/nvm.sh" ]; then
    # Загружаем nvm если еще не загружен
    if ! command -v nvm &> /dev/null && [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    fi
    
    if [ "$CURRENT_NODE_VERSION" != "$REQUIRED_NODE_VERSION" ]; then
        echo -e "${YELLOW}Переключение на Node.js v${REQUIRED_NODE_VERSION}...${NC}"
        nvm use $REQUIRED_NODE_VERSION 2>/dev/null || nvm install $REQUIRED_NODE_VERSION
        
        # Проверяем успешность переключения
        NEW_NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NEW_NODE_VERSION" = "$REQUIRED_NODE_VERSION" ]; then
            echo -e "${GREEN}✅ Переключено на Node.js v${REQUIRED_NODE_VERSION}${NC}"
        else
            echo -e "${YELLOW}Не удалось переключить версию Node.js, продолжаем с текущей${NC}"
        fi
    else
        echo -e "${GREEN}✅ Используется рекомендуемая версия Node.js${NC}"
    fi
elif [ "$CURRENT_NODE_VERSION" -lt "$REQUIRED_NODE_VERSION" ]; then
    echo -e "${YELLOW}Рекомендуется Node.js v${REQUIRED_NODE_VERSION} или выше${NC}"
    echo "   Установите nvm для управления версиями Node.js:"
    echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
fi

# Очистка старых зависимостей если они установлены от root
if [ -d "backend/node_modules" ] && [ "$(stat -c %U backend/node_modules 2>/dev/null || stat -f %Su backend/node_modules 2>/dev/null)" = "root" ]; then
    echo -e "${YELLOW}Очистка старых зависимостей backend...${NC}"
    rm -rf backend/node_modules backend/package-lock.json
fi

if [ -d "frontend/node_modules" ] && [ "$(stat -c %U frontend/node_modules 2>/dev/null || stat -f %Su frontend/node_modules 2>/dev/null)" = "root" ]; then
    echo -e "${YELLOW}Очистка старых зависимостей frontend...${NC}"
    rm -rf frontend/node_modules frontend/package-lock.json
fi

# Создание базы данных и таблиц
echo -e "${GREEN}Настройка базы данных...${NC}"

# Проверяем, запущен ли PostgreSQL
if ! pg_isready -q 2>/dev/null; then
    echo -e "${YELLOW}PostgreSQL не запущен. Пытаемся запустить...${NC}"
    
    # Для systemd систем
    if command -v systemctl &> /dev/null; then
        # Проверяем какой именно сервис PostgreSQL установлен
        if systemctl list-units --all | grep -q "postgresql@"; then
            echo "   Попробуйте выполнить: sudo systemctl start postgresql@*-main"
        elif systemctl list-units --all | grep -q "postgresql-"; then
            PG_SERVICE=$(systemctl list-units --all | grep "postgresql-" | head -1 | awk '{print $1}')
            echo "   Попробуйте выполнить: sudo systemctl start $PG_SERVICE"
        else
            echo "   Попробуйте выполнить: sudo systemctl start postgresql"
            echo "   Если не работает, сначала установите PostgreSQL: ./install-postgres.sh"
        fi
    # Для macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   Попробуйте выполнить: brew services start postgresql"
    else
        echo "   Запустите PostgreSQL вручную согласно документации вашей системы"
    fi
    
    echo ""
    echo -e "${RED}Не удалось подключиться к PostgreSQL${NC}"
    echo "   Убедитесь, что PostgreSQL запущен и доступен"
    exit 1
fi

# Настройка базы данных
echo "   Создание базы данных и пользователя..."

# Создаем временный SQL файл
cat > /tmp/setup_crm_db.sql << 'EOF'
-- Создание пользователя если не существует
DO
$$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
      CREATE ROLE postgres WITH LOGIN PASSWORD 'password' SUPERUSER;
   END IF;
END
$$;

-- Установка пароля для пользователя postgres
ALTER USER postgres PASSWORD 'password';

-- Создание базы данных
SELECT 'CREATE DATABASE crm_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'crm_db')\gexec

-- Подключение к базе и создание таблицы
\c crm_db

CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    company VARCHAR(255)
);

-- Добавление тестовых данных, если таблица пустая
INSERT INTO clients (name, email, phone, company)
SELECT 'Иван Иванов', 'ivan@example.com', '+7 (999) 123-45-67', 'ООО Рога и Копыта'
WHERE NOT EXISTS (SELECT 1 FROM clients LIMIT 1);

INSERT INTO clients (name, email, phone, company)
SELECT 'Петр Петров', 'petr@example.com', '+7 (999) 987-65-43', 'АО Ромашка'
WHERE NOT EXISTS (SELECT 1 FROM clients WHERE email = 'petr@example.com');
EOF

# Выполняем SQL скрипт
if command -v sudo &> /dev/null; then
    sudo -u postgres psql -f /tmp/setup_crm_db.sql 2>/dev/null || psql -U postgres -f /tmp/setup_crm_db.sql
else
    psql -U postgres -f /tmp/setup_crm_db.sql
fi

# Удаляем временный файл
rm -f /tmp/setup_crm_db.sql

echo -e "${GREEN}✅ База данных настроена${NC}"

# Установка зависимостей backend
echo ""
echo -e "${GREEN}Установка зависимостей backend...${NC}"
cd backend
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка установки зависимостей backend${NC}"
    exit 1
fi

# Запуск backend в фоне
echo -e "${GREEN}Запуск backend...${NC}"
npm start &
BACKEND_PID=$!
cd ..

# Ждем запуска backend
echo "   Ожидание запуска backend..."
sleep 3

# Проверяем, что backend запустился
if ! curl -s http://localhost:3001/api/clients > /dev/null; then
    echo -e "${YELLOW}Backend может быть не готов, продолжаем...${NC}"
fi

# Установка зависимостей frontend
echo ""
echo -e "${GREEN}Установка зависимостей frontend...${NC}"
cd frontend
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка установки зависимостей frontend${NC}"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# Функция для корректного завершения процессов
cleanup() {
    echo ""
    echo -e "${YELLOW}Остановка приложения...${NC}"
    kill $BACKEND_PID 2>/dev/null
    exit 0
}

# Перехват сигнала прерывания
trap cleanup INT TERM

# Запуск frontend
echo -e "${GREEN}апуск frontend...${NC}"
echo ""
echo -e "${GREEN}✅ Приложение запущено!${NC}"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:3001"
echo ""
echo "Для остановки нажмите Ctrl+C"
echo ""

# Запуск frontend (блокирующий вызов)
npm start

# Если frontend завершился, останавливаем backend
cleanup