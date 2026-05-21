-- Bishkek Courier Vision Database Schema

-- Users table (Couriers)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    courier_id VARCHAR(100) NOT NULL UNIQUE,
    aggregator ENUM('yandex_pro', 'glovo') NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    balance INT DEFAULT 0,
    multiplier DECIMAL(3,2) DEFAULT 1.00,
    weekly_contributions INT DEFAULT 0,
    status ENUM('novice', 'helper', 'expert', 'master') DEFAULT 'novice',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_courier_id (courier_id),
    INDEX idx_aggregator (aggregator)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Addresses table (Buildings/Complexes)
CREATE TABLE IF NOT EXISTS addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    building_type ENUM('residential', 'office', 'mixed') DEFAULT 'residential',
    total_entrances INT DEFAULT 1,
    has_security BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_location (latitude, longitude),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Contributions table (User submissions)
CREATE TABLE IF NOT EXISTS contributions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NOT NULL,
    type ENUM('photo', 'hint', 'code') NOT NULL,
    status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    points INT DEFAULT 0,
    ai_confidence DECIMAL(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE CASCADE,
    INDEX idx_user_contributions (user_id, created_at),
    INDEX idx_address_contributions (address_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Entrance Photos table
CREATE TABLE IF NOT EXISTS entrance_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contribution_id INT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    entrance_number INT,
    ai_verified BOOLEAN DEFAULT FALSE,
    ai_verification_result JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contribution_id) REFERENCES contributions(id) ON DELETE CASCADE,
    INDEX idx_address_photos (contribution_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Intercom Codes table
CREATE TABLE IF NOT EXISTS intercom_codes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    entrance_number INT,
    gate_number VARCHAR(50),
    verified_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE CASCADE,
    INDEX idx_address_codes (address_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Hints table (Text tips from couriers)
CREATE TABLE IF NOT EXISTS hints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contribution_id INT NOT NULL,
    hint_text TEXT NOT NULL,
    helpful_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contribution_id) REFERENCES contributions(id) ON DELETE CASCADE,
    INDEX idx_contribution_hints (contribution_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Points History table
CREATE TABLE IF NOT EXISTS points_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    contribution_id INT,
    points_earned INT NOT NULL,
    multiplier_applied DECIMAL(3,2) DEFAULT 1.00,
    reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (contribution_id) REFERENCES contributions(id) ON DELETE SET NULL,
    INDEX idx_user_points (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;