CREATE TABLE IF NOT EXISTS clients (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(50),
  company VARCHAR(255)
);

-- Test data
INSERT INTO clients (name, email, phone, company)
VALUES
  ('Иван Петров', 'ivan@example.com', '+79001234567', 'Компания 1'),
  ('Анна Сидорова', 'anna@example.com', '+79007654321', 'Компания 2');
