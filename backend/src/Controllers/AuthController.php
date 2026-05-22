<?php

namespace App\Controllers;

use App\Database;
use App\Models\User;
use Firebase\JWT\JWT;

class AuthController
{
    private $db;
    private $userModel;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->userModel = new User($this->db);
    }

    /**
     * Login courier
     * POST /api/auth/login
     * 
     * Request: {
     *   "courier_id": "4821",
     *   "aggregator": "yandex_pro"
     * }
     */
    public function login($data)
    {
        // Validate input
        if (empty($data['courier_id']) || empty($data['aggregator'])) {
            return [
                'status' => 'error',
                'message' => 'Courier ID and aggregator are required',
                'code' => 400
            ];
        }

        $courierId = $data['courier_id'];
        $aggregator = $data['aggregator'];

        // Validate aggregator
        if (!in_array($aggregator, ['yandex_pro', 'glovo'])) {
            return [
                'status' => 'error',
                'message' => 'Invalid aggregator. Use yandex_pro or glovo',
                'code' => 400
            ];
        }

        // Check if user exists
        $user = $this->userModel->findByCourierId($courierId, $aggregator);

        if (!$user) {
            // Create new user (first time login)
            $userId = $this->userModel->create([
                'courier_id' => $courierId,
                'aggregator' => $aggregator,
                'balance' => 0,
                'multiplier' => 1.00,
                'weekly_contributions' => 0,
                'status' => 'novice'
            ]);

            $user = $this->userModel->findById($userId);
        }

        // Generate JWT token
        $token = $this->generateToken($user);

        return [
            'status' => 'success',
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user['id'],
                    'courier_id' => $user['courier_id'],
                    'aggregator' => $user['aggregator'],
                    'full_name' => $user['full_name'],
                    'balance' => (int)$user['balance'],
                    'multiplier' => (float)$user['multiplier'],
                    'weekly_contributions' => (int)$user['weekly_contributions'],
                    'status' => $user['status']
                ],
                'token' => $token
            ],
            'code' => 200
        ];
    }

    /**
     * Get current user profile
     * GET /api/auth/me
     */
    public function me($userId)
    {
        $user = $this->userModel->findById($userId);

        if (!$user) {
            return [
                'status' => 'error',
                'message' => 'User not found',
                'code' => 404
            ];
        }

        // Get user's points history
        $history = $this->userModel->getPointsHistory($userId, 10);

        return [
            'status' => 'success',
            'data' => [
                'user' => [
                    'id' => $user['id'],
                    'courier_id' => $user['courier_id'],
                    'aggregator' => $user['aggregator'],
                    'full_name' => $user['full_name'],
                    'balance' => (int)$user['balance'],
                    'multiplier' => (float)$user['multiplier'],
                    'weekly_contributions' => (int)$user['weekly_contributions'],
                    'status' => $user['status']
                ],
                'recent_activity' => $history
            ],
            'code' => 200
        ];
    }

    /**
     * Generate JWT token
     */
    private function generateToken($user)
    {
        $secretKey = $_ENV['JWT_SECRET'] ?? 'your_secret_key_change_in_production';
        $issuedAt = time();
        $expirationTime = $issuedAt + (60 * 60 * 24 * 30); // 30 days

        $payload = [
            'iat' => $issuedAt,
            'exp' => $expirationTime,
            'user_id' => $user['id'],
            'courier_id' => $user['courier_id'],
            'aggregator' => $user['aggregator']
        ];

        return JWT::encode($payload, $secretKey, 'HS256');
    }
}