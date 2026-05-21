-- Seed data for testing

-- Insert test addresses in Bishkek
INSERT INTO addresses (name, address, latitude, longitude, building_type, total_entrances, has_security) VALUES
('ЖК Асанбай Сити, Блок 3', 'ул. Токтоналиева 21/4, кв. 58', 42.8746, 74.5698, 'residential', 3, TRUE),
('ЖК Южные Ворота, корп. 2', 'ул. Ахунбаева 110', 42.8156, 74.5947, 'residential', 4, TRUE),
('ЖК Мурас Ордо', 'ул. Жукеева-Пудовкина 4', 42.8234, 74.5812, 'residential', 2, FALSE);

-- Insert test user (courier)
INSERT INTO users (courier_id, aggregator, full_name, phone, balance, multiplier, weekly_contributions, status) VALUES
('4821', 'yandex_pro', 'Тестовый Курьер', '+996555123456', 110, 1.20, 5, 'helper');

-- Insert some test contributions
INSERT INTO contributions (user_id, address_id, type, status, points, ai_confidence) VALUES
(1, 1, 'photo', 'verified', 10, 0.95),
(1, 1, 'code', 'verified', 15, NULL),
(1, 2, 'hint', 'verified', 5, NULL);

-- Insert intercom codes
INSERT INTO intercom_codes (address_id, code, entrance_number, gate_number, verified_count) VALUES
(1, '123#4567', 2, 'Калитка №2', 5),
(2, '456#7890', 1, 'Центр', 3);

-- Insert hints
INSERT INTO hints (contribution_id, hint_text, helpful_count) VALUES
(3, 'Вход справа от аптеки «Неман». Через двор до второго подъезда.', 12);

-- Insert points history
INSERT INTO points_history (user_id, contribution_id, points_earned, multiplier_applied, reason) VALUES
(1, 1, 10, 1.00, 'Фото входа'),
(1, 2, 15, 1.00, 'Код домофона'),
(1, 3, 5, 1.20, 'Подсказка (бонус x1.2)');