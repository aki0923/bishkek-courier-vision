<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

// Load environment variables
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// ✅ CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request info
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($requestUri, PHP_URL_PATH);
$uri = rtrim($uri, '/');

// Get input data
$input = json_decode(file_get_contents('php://input'), true) ?? [];

// Get query params
parse_str(parse_url($requestUri, PHP_URL_QUERY) ?? '', $params);

// ============================================
// DATABASE CONNECTION
// ============================================
function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        $host = $_ENV['DB_HOST'] ?? 'mysql';
        $dbname = $_ENV['DB_NAME'] ?? 'bishkek_courier';
        $username = $_ENV['DB_USER'] ?? 'courierapp';
        $password = $_ENV['DB_PASSWORD'] ?? 'courierpass123';

        try {
            $pdo = new PDO(
                "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
                $username,
                $password,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        } catch (Exception $e) {
            sendResponse(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()], 500);
        }
    }
    return $pdo;
}

// ============================================
// HELPER FUNCTIONS
// ============================================
function sendResponse($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

function getAuthUserId() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (empty($authHeader)) return null;

    $token = str_replace('Bearer ', '', $authHeader);

    try {
        $secret = $_ENV['JWT_SECRET'] ?? 'my_super_secret_key_change_in_production_12345';
        $decoded = \Firebase\JWT\JWT::decode(
            $token,
            new \Firebase\JWT\Key($secret, 'HS256')
        );
        return $decoded->user_id ?? null;
    } catch (Exception $e) {
        return null;
    }
}

function generateToken($user) {
    $secret = $_ENV['JWT_SECRET'] ?? 'my_super_secret_key_change_in_production_12345';
    $payload = [
        'iat' => time(),
        'exp' => time() + (60 * 60 * 24 * 30),
        'user_id' => $user['id'],
        'courier_id' => $user['courier_id'],
        'aggregator' => $user['aggregator']
    ];
    return \Firebase\JWT\JWT::encode($payload, $secret, 'HS256');
}

function requireAuth() {
    $userId = getAuthUserId();
    if (!$userId) {
        sendResponse(['status' => 'error', 'message' => 'Authentication required'], 401);
    }
    return $userId;
}

function calculateStatus($balance) {
    if ($balance >= 501) return 'master';
    if ($balance >= 201) return 'expert';
    if ($balance >= 51) return 'helper';
    return 'novice';
}

function calculateMultiplier($weeklyContributions) {
    if ($weeklyContributions >= 20) return 2.00;
    if ($weeklyContributions >= 10) return 1.50;
    if ($weeklyContributions >= 5) return 1.20;
    return 1.00;
}

// ============================================
// ROUTING
// ============================================
try {

    // ── ROOT ────────────────────────────────
    if ($uri === '' || $uri === '/') {
        sendResponse([
            'status' => 'success',
            'message' => 'Bishkek Courier Vision API v1.0',
            'endpoints' => [
                'POST /api/auth/login',
                'GET /api/addresses',
                'GET /api/addresses/nearby',
                'GET /api/addresses/{id}',
                'GET /api/addresses/search',
                'GET /api/profile',
                'GET /api/profile/history',
                'POST /api/contributions',
                'GET /api/health'
            ]
        ]);
    }

    // ── HEALTH CHECK ────────────────────────
    if ($uri === '/api/health') {
        $db = getDB();
        $stmt = $db->query("SELECT 1");
        sendResponse([
            'status' => 'healthy',
            'timestamp' => date('Y-m-d H:i:s'),
            'database' => 'connected',
            'version' => '1.0.0'
        ]);
    }

    // ── AUTH: LOGIN ─────────────────────────
    if ($uri === '/api/auth/login' && $requestMethod === 'POST') {
        $courierId = trim($input['courier_id'] ?? '');
        $aggregator = trim($input['aggregator'] ?? '');

        if (empty($courierId) || empty($aggregator)) {
            sendResponse(['status' => 'error', 'message' => 'courier_id and aggregator are required'], 400);
        }

        if (!in_array($aggregator, ['yandex_pro', 'glovo'])) {
            sendResponse(['status' => 'error', 'message' => 'Invalid aggregator'], 400);
        }

        $db = getDB();

        // Find or create user
        $stmt = $db->prepare("SELECT * FROM users WHERE courier_id = ? AND aggregator = ? LIMIT 1");
        $stmt->execute([$courierId, $aggregator]);
        $user = $stmt->fetch();

        if (!$user) {
            // Create new user
            $stmt = $db->prepare("INSERT INTO users
                (courier_id, aggregator, balance, multiplier, weekly_contributions, status)
                VALUES (?, ?, 0, 1.00, 0, 'novice')");
            $stmt->execute([$courierId, $aggregator]);
            $userId = $db->lastInsertId();

            $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
        }

        $token = generateToken($user);

        sendResponse([
            'status' => 'success',
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => (int)$user['id'],
                    'courier_id' => $user['courier_id'],
                    'aggregator' => $user['aggregator'],
                    'balance' => (int)$user['balance'],
                    'multiplier' => (float)$user['multiplier'],
                    'weekly_contributions' => (int)$user['weekly_contributions'],
                    'status' => $user['status']
                ],
                'token' => $token
            ]
        ]);
    }

    // ── AUTH: ME ────────────────────────────
    if ($uri === '/api/auth/me' && $requestMethod === 'GET') {
        $userId = requireAuth();
        $db = getDB();

        $stmt = $db->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            sendResponse(['status' => 'error', 'message' => 'User not found'], 404);
        }

        sendResponse([
            'status' => 'success',
            'data' => [
                'user' => [
                    'id' => (int)$user['id'],
                    'courier_id' => $user['courier_id'],
                    'aggregator' => $user['aggregator'],
                    'balance' => (int)$user['balance'],
                    'multiplier' => (float)$user['multiplier'],
                    'weekly_contributions' => (int)$user['weekly_contributions'],
                    'status' => $user['status']
                ]
            ]
        ]);
    }

    // ── ADDRESSES: NEARBY ───────────────────
    if ($uri === '/api/addresses/nearby' && $requestMethod === 'GET') {
        $lat = (float)($params['lat'] ?? 42.8746);
        $lng = (float)($params['lng'] ?? 74.5698);
        $radius = (int)($params['radius'] ?? 2000);

        $db = getDB();

        $stmt = $db->prepare("
            SELECT *,
            (6371000 * acos(
                cos(radians(:lat1)) * cos(radians(latitude)) *
                cos(radians(longitude) - radians(:lng)) +
                sin(radians(:lat2)) * sin(radians(latitude))
            )) AS distance
            FROM addresses
            HAVING distance < :radius
            ORDER BY distance
            LIMIT 20
        ");
        $stmt->execute([
            ':lat1' => $lat,
            ':lat2' => $lat,
            ':lng' => $lng,
            ':radius' => $radius
        ]);
        $addresses = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => $addresses,
            'center' => ['latitude' => $lat, 'longitude' => $lng],
            'total' => count($addresses)
        ]);
    }

    // ── ADDRESSES: SEARCH ───────────────────
    if ($uri === '/api/addresses/search' && $requestMethod === 'GET') {
        $query = $params['q'] ?? '';

        if (empty($query)) {
            sendResponse(['status' => 'error', 'message' => 'Query parameter q is required'], 400);
        }

        $db = getDB();
        $searchTerm = "%{$query}%";

        $stmt = $db->prepare("SELECT * FROM addresses WHERE name LIKE ? OR address LIKE ? LIMIT 20");
        $stmt->execute([$searchTerm, $searchTerm]);
        $results = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => $results,
            'total' => count($results)
        ]);
    }

    // ── ADDRESSES: GET BY ID ────────────────
    if (preg_match('/^\/api\/addresses\/(\d+)$/', $uri, $matches) && $requestMethod === 'GET') {
        $addressId = (int)$matches[1];
        $db = getDB();

        // Get address
        $stmt = $db->prepare("SELECT * FROM addresses WHERE id = ? LIMIT 1");
        $stmt->execute([$addressId]);
        $address = $stmt->fetch();

        if (!$address) {
            sendResponse(['status' => 'error', 'message' => 'Address not found'], 404);
        }

        // Get photos
        $stmt = $db->prepare("
            SELECT ep.*, c.created_at as uploaded_at
            FROM entrance_photos ep
            JOIN contributions c ON ep.contribution_id = c.id
            WHERE c.address_id = ? AND c.status = 'verified'
            ORDER BY ep.created_at DESC LIMIT 10
        ");
        $stmt->execute([$addressId]);
        $photos = $stmt->fetchAll();

        // Get codes
        $stmt = $db->prepare("SELECT * FROM intercom_codes WHERE address_id = ? AND is_active = 1");
        $stmt->execute([$addressId]);
        $codes = $stmt->fetchAll();

        // Get hints
        $stmt = $db->prepare("
            SELECT h.*, c.created_at
            FROM hints h
            JOIN contributions c ON h.contribution_id = c.id
            WHERE c.address_id = ? AND c.status = 'verified'
            ORDER BY h.helpful_count DESC LIMIT 5
        ");
        $stmt->execute([$addressId]);
        $hints = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => [
                'address' => $address,
                'entrance_photos' => $photos,
                'intercom_codes' => $codes,
                'hints' => $hints
            ]
        ]);
    }

    // ── ADDRESSES: GET ALL ──────────────────
    if ($uri === '/api/addresses' && $requestMethod === 'GET') {
        $limit = (int)($params['limit'] ?? 50);
        $offset = (int)($params['offset'] ?? 0);

        $db = getDB();
        $stmt = $db->prepare("SELECT * FROM addresses ORDER BY created_at DESC LIMIT ? OFFSET ?");
        $stmt->execute([$limit, $offset]);
        $addresses = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => $addresses,
            'total' => count($addresses)
        ]);
    }

    // ── PROFILE ─────────────────────────────
    if ($uri === '/api/profile' && $requestMethod === 'GET') {
        $userId = requireAuth();
        $db = getDB();

        $stmt = $db->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            sendResponse(['status' => 'error', 'message' => 'User not found'], 404);
        }

        // Statistics
        $stmt = $db->prepare("
            SELECT
                COUNT(*) as total_contributions,
                SUM(CASE WHEN type='photo' THEN 1 ELSE 0 END) as photos_submitted,
                SUM(CASE WHEN type='hint' THEN 1 ELSE 0 END) as hints_shared,
                SUM(CASE WHEN type='code' THEN 1 ELSE 0 END) as codes_added,
                SUM(CASE WHEN status='verified' THEN 1 ELSE 0 END) as verified_contributions,
                SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) as pending_review
            FROM contributions WHERE user_id = ?
        ");
        $stmt->execute([$userId]);
        $stats = $stmt->fetch();

        // Weekly goal
        $weekly = (int)$user['weekly_contributions'];
        $goals = [
            ['target' => 5,  'multiplier' => 1.2, 'status' => 'Помощник'],
            ['target' => 10, 'multiplier' => 1.5, 'status' => 'Эксперт'],
            ['target' => 20, 'multiplier' => 2.0, 'status' => 'Мастер'],
        ];

        $currentGoal = $goals[0];
        foreach ($goals as $goal) {
            if ($weekly < $goal['target']) {
                $currentGoal = $goal;
                break;
            }
        }

        $weeklyGoal = [
            'current_count' => $weekly,
            'target' => $currentGoal['target'],
            'progress_percent' => min(100, round(($weekly / $currentGoal['target']) * 100)),
            'multiplier_target' => $currentGoal['multiplier'],
            'status_target' => $currentGoal['status'],
            'remaining' => max(0, $currentGoal['target'] - $weekly)
        ];

        // Recent contributions
        $stmt = $db->prepare("
            SELECT c.*, a.name as address_name, a.address
            FROM contributions c
            JOIN addresses a ON c.address_id = a.id
            WHERE c.user_id = ?
            ORDER BY c.created_at DESC LIMIT 10
        ");
        $stmt->execute([$userId]);
        $recentContributions = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => [
                'user' => [
                    'id' => (int)$user['id'],
                    'courier_id' => $user['courier_id'],
                    'aggregator' => $user['aggregator'],
                    'balance' => (int)$user['balance'],
                    'multiplier' => (float)$user['multiplier'],
                    'weekly_contributions' => $weekly,
                    'status' => $user['status']
                ],
                'statistics' => $stats,
                'weekly_goal' => $weeklyGoal,
                'recent_contributions' => $recentContributions
            ]
        ]);
    }

    // ── PROFILE: HISTORY ────────────────────
    if ($uri === '/api/profile/history' && $requestMethod === 'GET') {
        $userId = requireAuth();
        $limit = (int)($params['limit'] ?? 20);
        $offset = (int)($params['offset'] ?? 0);

        $db = getDB();
        $stmt = $db->prepare("
            SELECT c.*, a.name as address_name, a.address
            FROM contributions c
            JOIN addresses a ON c.address_id = a.id
            WHERE c.user_id = ?
            ORDER BY c.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$userId, $limit, $offset]);
        $history = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => $history,
            'total' => count($history)
        ]);
    }

    // ── CONTRIBUTIONS: CREATE ───────────────
    if ($uri === '/api/contributions' && $requestMethod === 'POST') {
        $userId = requireAuth();

        $type = $input['type'] ?? '';
        $addressId = (int)($input['address_id'] ?? 0);

        if (empty($type) || empty($addressId)) {
            sendResponse(['status' => 'error', 'message' => 'type and address_id are required'], 400);
        }

        if (!in_array($type, ['photo', 'hint', 'code'])) {
            sendResponse(['status' => 'error', 'message' => 'Invalid type'], 400);
        }

        $db = getDB();

        // Points per type
        $pointsMap = ['photo' => 10, 'hint' => 5, 'code' => 15];
        $points = $pointsMap[$type];

        // Get user multiplier
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        $multiplier = (float)$user['multiplier'];
        $finalPoints = (int)($points * $multiplier);

        // Create contribution
        $stmt = $db->prepare("
            INSERT INTO contributions (user_id, address_id, type, status, points)
            VALUES (?, ?, ?, 'verified', ?)
        ");
        $stmt->execute([$userId, $addressId, $type, $finalPoints]);
        $contributionId = $db->lastInsertId();

        // Handle type-specific data
        if ($type === 'hint' && !empty($input['hint_text'])) {
            $stmt = $db->prepare("INSERT INTO hints (contribution_id, hint_text) VALUES (?, ?)");
            $stmt->execute([$contributionId, $input['hint_text']]);
        }

        if ($type === 'code' && !empty($input['code'])) {
            $stmt = $db->prepare("
                INSERT INTO intercom_codes (address_id, code, entrance_number, gate_number)
                VALUES (?, ?, ?, ?)
            ");
            $stmt->execute([
                $addressId,
                $input['code'],
                $input['entrance_number'] ?? null,
                $input['gate_number'] ?? null
            ]);
        }

        if ($type === 'photo' && !empty($input['photo_url'])) {
            $stmt = $db->prepare("
                INSERT INTO entrance_photos (contribution_id, photo_url, entrance_number, ai_verified)
                VALUES (?, ?, ?, 1)
            ");
            $stmt->execute([$contributionId, $input['photo_url'], $input['entrance_number'] ?? null]);
        }

        // Update user balance
        $stmt = $db->prepare("
            UPDATE users
            SET balance = balance + ?,
                weekly_contributions = weekly_contributions + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ");
        $stmt->execute([$finalPoints, $userId]);

        // Update multiplier based on weekly contributions
        $newWeekly = (int)$user['weekly_contributions'] + 1;
        $newMultiplier = calculateMultiplier($newWeekly);
        $newStatus = calculateStatus((int)$user['balance'] + $finalPoints);

        $stmt = $db->prepare("UPDATE users SET multiplier = ?, status = ? WHERE id = ?");
        $stmt->execute([$newMultiplier, $newStatus, $userId]);

        // Record points history
        $stmt = $db->prepare("
            INSERT INTO points_history (user_id, contribution_id, points_earned, multiplier_applied, reason)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([$userId, $contributionId, $finalPoints, $multiplier, ucfirst($type) . ' добавлен']);

        sendResponse([
            'status' => 'success',
            'message' => 'Contribution created successfully',
            'data' => [
                'contribution_id' => (int)$contributionId,
                'points_earned' => $finalPoints,
                'multiplier_applied' => $multiplier,
                'new_balance' => (int)$user['balance'] + $finalPoints
            ]
        ], 201);
    }

    // ── CONTRIBUTIONS: GET ──────────────────
    if ($uri === '/api/contributions' && $requestMethod === 'GET') {
        $userId = requireAuth();
        $limit = (int)($params['limit'] ?? 20);
        $offset = (int)($params['offset'] ?? 0);

        $db = getDB();
        $stmt = $db->prepare("
            SELECT c.*, a.name as address_name
            FROM contributions c
            JOIN addresses a ON c.address_id = a.id
            WHERE c.user_id = ?
            ORDER BY c.created_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([$userId, $limit, $offset]);
        $contributions = $stmt->fetchAll();

        sendResponse([
            'status' => 'success',
            'data' => $contributions,
            'total' => count($contributions)
        ]);
    }

    // ── 404 ─────────────────────────────────
    sendResponse([
        'status' => 'error',
        'message' => 'Endpoint not found: ' . $uri,
        'method' => $requestMethod
    ], 404);

} catch (Exception $e) {
    sendResponse([
        'status' => 'error',
        'message' => 'Server error: ' . $e->getMessage()
    ], 500);
}
