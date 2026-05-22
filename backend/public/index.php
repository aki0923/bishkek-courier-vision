<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;
use App\Controllers\AuthController;
use App\Controllers\AddressController;
use App\Controllers\ProfileController;
use App\Controllers\ContributionController;

// Load environment variables
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request info
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($requestUri, PHP_URL_PATH);

// Get input data
$input = json_decode(file_get_contents('php://input'), true) ?? [];

// Get query params
parse_str(parse_url($requestUri, PHP_URL_QUERY) ?? '', $params);

// Simple JWT authentication middleware (extract user_id from token)
$userId = getAuthenticatedUserId();

// Router
try {
    $response = null;

    switch (true) {
        // Auth endpoints
        case $uri === '/api/auth/login' && $requestMethod === 'POST':
            $controller = new AuthController();
            $response = $controller->login($input);
            break;

        case $uri === '/api/auth/me' && $requestMethod === 'GET':
            requireAuth($userId);
            $controller = new AuthController();
            $response = $controller->me($userId);
            break;

        // Address endpoints
        case $uri === '/api/addresses' && $requestMethod === 'GET':
            $controller = new AddressController();
            $response = $controller->getAll($params);
            break;

        case $uri === '/api/addresses/nearby' && $requestMethod === 'GET':
            $controller = new AddressController();
            $response = $controller->getNearby($params);
            break;

        case preg_match('/^\/api\/addresses\/(\d+)$/', $uri, $matches) && $requestMethod === 'GET':
            $controller = new AddressController();
            $response = $controller->getById($matches[1]);
            break;

        case $uri === '/api/addresses/search' && $requestMethod === 'GET':
            $controller = new AddressController();
            $response = $controller->search($params);
            break;

        // Profile endpoints
        case $uri === '/api/profile' && $requestMethod === 'GET':
            requireAuth($userId);
            $controller = new ProfileController();
            $response = $controller->getProfile($userId);
            break;

        case $uri === '/api/profile/history' && $requestMethod === 'GET':
            requireAuth($userId);
            $controller = new ProfileController();
            $response = $controller->getHistory($userId, $params);
            break;

        // Contribution endpoints
        case $uri === '/api/contributions' && $requestMethod === 'POST':
            requireAuth($userId);
            $controller = new ContributionController();
            $response = $controller->create($userId, $input);
            break;

        case preg_match('/^\/api\/contributions\/(\d+)\/verify$/', $uri, $matches) && $requestMethod === 'PUT':
            $controller = new ContributionController();
            $response = $controller->verify($matches[1], $input);
            break;

        case $uri === '/api/contributions' && $requestMethod === 'GET':
            requireAuth($userId);
            $controller = new ContributionController();
            $response = $controller->getByUser($userId, $params);
            break;

        // Health check
        case $uri === '/api/health':
            $response = [
                'status' => 'healthy',
                'timestamp' => date('Y-m-d H:i:s'),
                'code' => 200
            ];
            break;

        default:
            $response = [
                'status' => 'error',
                'message' => 'Endpoint not found',
                'code' => 404
            ];
            break;
    }

    // Send response
    http_response_code($response['code'] ?? 200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Internal server error',
        'error' => $e->getMessage()
    ]);
}

// Helper functions
function getAuthenticatedUserId()
{
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';

    if (empty($authHeader)) {
        return null;
    }

    // Extract token from "Bearer {token}"
    $token = str_replace('Bearer ', '', $authHeader);

    try {
        // Decode JWT (simplified - use proper JWT library in production)
        $secretKey = $_ENV['JWT_SECRET'] ?? 'your_secret_key_change_in_production';
        $decoded = \Firebase\JWT\JWT::decode($token, new \Firebase\JWT\Key($secretKey, 'HS256'));
        return $decoded->user_id ?? null;
    } catch (Exception $e) {
        return null;
    }
}

function requireAuth($userId)
{
    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            'status' => 'error',
            'message' => 'Authentication required'
        ]);
        exit;
    }
}
// recommmit