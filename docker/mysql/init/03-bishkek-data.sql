-- Real Bishkek addresses for demo
INSERT INTO addresses (name, address, latitude, longitude, building_type, total_entrances, has_security) VALUES
-- Центр
('ЖК Асанбай Сити, Блок 1', 'ул. Токтоналиева 21/1', 42.8746, 74.5698, 'residential', 4, TRUE),
('ЖК Асанбай Сити, Блок 2', 'ул. Токтоналиева 21/2', 42.8747, 74.5699, 'residential', 3, TRUE),
('ЖК Асанбай Сити, Блок 3', 'ул. Токтоналиева 21/3', 42.8745, 74.5700, 'residential', 4, TRUE),
('ЖК Асанбай Сити, Блок 4', 'ул. Токтоналиева 21/4', 42.8744, 74.5697, 'residential', 3, TRUE),

-- Восток
('ЖК Южные Ворота, корп. 1', 'ул. Ахунбаева 110', 42.8156, 74.5947, 'residential', 4, TRUE),
('ЖК Южные Ворота, корп. 2', 'ул. Ахунбаева 112', 42.8158, 74.5949, 'residential', 4, TRUE),
('ЖК Южные Ворота, корп. 3', 'ул. Ахунбаева 114', 42.8160, 74.5951, 'residential', 4, TRUE),

-- Запад
('ЖК Мурас Ордо', 'ул. Жукеева-Пудовкина 4', 42.8234, 74.5812, 'residential', 2, FALSE),
('ЖК Мурас Ордо 2', 'ул. Жукеева-Пудовкина 6', 42.8236, 74.5814, 'residential', 3, FALSE),

-- Юг
('ЖК Бишкек Парк', 'мкр. Джал-23, д. 5', 42.8467, 74.6189, 'residential', 6, TRUE),
('ЖК Манас Сити', 'мкр. Учкун, д. 12', 42.8534, 74.5612, 'residential', 4, TRUE),

-- Север
('ЖК Боконбаева Резиденс', 'ул. Боконбаева 198', 42.8823, 74.5723, 'residential', 3, FALSE),
('ЖК Премьер Парк', 'ул. Гоголя 90', 42.8945, 74.5834, 'residential', 5, TRUE),

-- Микрорайоны
('Микрорайон Тунгуч, д. 5', 'мкр. Тунгуч, д. 5', 42.8512, 74.5934, 'residential', 4, FALSE),
('Микрорайон Аламедин-1, д. 47', 'мкр. Аламедин-1, д. 47', 42.8623, 74.6045, 'residential', 6, FALSE),

-- Бизнес-центры
('БЦ Манас', 'пр. Чуй 165', 42.8745, 74.6034, 'office', 1, TRUE),
('ТРЦ Бишкек Парк', 'пр. Чуй 148/1', 42.8723, 74.5945, 'mixed', 4, TRUE);

-- Test users (couriers)
INSERT INTO users (courier_id, aggregator, full_name, phone, balance, multiplier, weekly_contributions, status) VALUES
('4821', 'yandex_pro', 'Тестовый Курьер', '+996555123456', 110, 1.20, 5, 'helper'),
('1234', 'glovo', 'Демо Курьер Glovo', '+996555654321', 250, 1.50, 12, 'expert'),
('5678', 'yandex_pro', 'Эксперт Курьер', '+996555789012', 580, 2.00, 25, 'master');

-- Test contributions
INSERT INTO contributions (user_id, address_id, type, status, points, ai_confidence) VALUES
-- User 1 (Тестовый Курьер)
(1, 1, 'photo', 'verified', 10, 0.95),
(1, 1, 'code', 'verified', 15, NULL),
(1, 2, 'hint', 'verified', 5, NULL),
(1, 3, 'photo', 'verified', 15, 0.92),
(1, 5, 'photo', 'verified', 10, 0.88),

-- User 2 (Демо Glovo)
(2, 1, 'hint', 'verified', 5, NULL),
(2, 2, 'photo', 'verified', 15, 0.94),
(2, 4, 'photo', 'verified', 10, 0.85),
(2, 5, 'code', 'verified', 15, NULL),
(2, 6, 'photo', 'verified', 10, 0.89),
(2, 7, 'hint', 'verified', 5, NULL),

-- User 3 (Master)
(3, 3, 'photo', 'verified', 15, 0.97),
(3, 6, 'code', 'verified', 15, NULL),
(3, 8, 'photo', 'verified', 10, 0.91),
(3, 9, 'hint', 'verified', 5, NULL),
(3, 10, 'photo', 'verified', 15, 0.93);

-- Intercom codes for various addresses
INSERT INTO intercom_codes (address_id, code, entrance_number, gate_number, verified_count, is_active) VALUES
(1, '123#4567', 1, 'Калитка №1', 8, 1),
(1, '234#5678', 2, 'Калитка №2', 5, 1),
(2, '345#6789', 1, 'Центральный вход', 3, 1),
(3, '456#7890', 1, 'Главные ворота', 7, 1),
(3, '567#8901', 2, 'Подъезд №2', 4, 1),
(4, '678#9012', 1, 'Калитка справа', 6, 1),
(5, '789#0123', 1, 'Восточные ворота', 9, 1),
(6, '890#1234', 1, 'Северный вход', 4, 1),
(7, '901#2345', 1, 'Главные ворота', 5, 1),
(8, '012#3456', 1, 'Калитка', 3, 1),
(10, 'B5#K2025', 1, 'Восточная калитка', 7, 1),
(11, '111#2222', 1, 'Главный вход', 6, 1),
(13, '333#4444', 1, 'Парадная', 4, 1);

-- Hints from couriers
INSERT INTO hints (contribution_id, hint_text, helpful_count) VALUES
(3, 'Вход справа от аптеки «Неман». Через двор до второго подъезда.', 12),
(6, 'Звонить на домофон только с 8 до 22, иначе никто не отвечает', 8),
(9, 'Калитка иногда не закрывается полностью - можно зайти без кода', 15),
(11, 'Консьерж требует показать заказ. Имейте экран с заказом наготове.', 10),
(14, 'Подъезд №3 нумерация необычная - вход через 1-й подъезд, потом направо', 6);

-- Entrance photos (URLs to placeholder images for demo)
INSERT INTO entrance_photos (contribution_id, photo_url, entrance_number, ai_verified) VALUES
(1, '/storage/uploads/asanbay_1_entrance.jpg', 1, 1),
(4, '/storage/uploads/asanbay_3_entrance.jpg', 2, 1),
(5, '/storage/uploads/yuzhnye_1.jpg', 1, 1),
(7, '/storage/uploads/asanbay_2_gate.jpg', 1, 1),
(8, '/storage/uploads/asanbay_4_door.jpg', 1, 1),
(10, '/storage/uploads/yuzhnye_2.jpg', 2, 1),
(12, '/storage/uploads/asanbay_3_main.jpg', 1, 1);

-- Points history (showing the gamification in action)
INSERT INTO points_history (user_id, contribution_id, points_earned, multiplier_applied, reason, created_at) VALUES
(1, 1, 10, 1.00, 'Фото входа', '2026-05-18 10:30:00'),
(1, 2, 15, 1.00, 'Код домофона', '2026-05-18 11:45:00'),
(1, 3, 5, 1.00, 'Подсказка', '2026-05-19 09:20:00'),
(1, 4, 18, 1.20, 'Фото входа (бонус x1.2)', '2026-05-20 14:15:00'),
(1, 5, 12, 1.20, 'Фото входа (бонус x1.2)', '2026-05-21 16:30:00'),
(1, NULL, 50, 1.00, 'Достижение: Статус Помощник', '2026-05-20 15:00:00');