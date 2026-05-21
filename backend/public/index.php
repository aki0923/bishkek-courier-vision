<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;

// Load environment variables
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Simple router
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string
$uri = parse_url($requestUri, PHP_URL_PATH);

// Basic routing
switch (true) {
    case $uri === '/':
        echo json_encode([
            'status' => 'success',
            'message' => 'Bishkek Courier Vision API v1.0',
            'endpoints' => [
                'POST /api/auth/login' => 'Login courier',
                'GET /api/addresses' => 'Get all addresses',
                'GET /api/addresses/{id}' => 'Get address details',
                'POST /api/contributions' => 'Submit contribution',
                'GET /api/profile' => 'Get user profile'
            ]
        ]);
        break;
        
    case preg_match('/^\/api\/health$/', $uri):
        echo json_encode([
            'status' => 'healthy',
            'timestamp' => date('Y-m-d H:i:s'),
            'database' => 'connected'
        ]);
        break;
        
    default:
        http_response_code(404);
        echo json_encode([
            'status' => 'error',
            'message' => 'Endpoint not found'
        ]);
        break;
}