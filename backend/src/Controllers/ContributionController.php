<?php

namespace App\Controllers;

use App\Database;
use App\Models\Contribution;
use App\Models\User;
use App\Services\AIService;

class ContributionController
{
    private $db;
    private $contributionModel;
    private $userModel;
    private $aiService;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->contributionModel = new Contribution($this->db);
        $this->userModel = new User($this->db);
        $this->aiService = new AIService();
    }

    /**
     * Submit a new contribution with AI verification
     */
    public function create($userId, $data)
    {
        // Validate input
        if (empty($data['address_id']) || empty($data['type'])) {
            return [
                'status' => 'error',
                'message' => 'Address ID and type are required',
                'code' => 400
            ];
        }

        $type = $data['type'];
        $addressId = $data['address_id'];

        // Validate type
        if (!in_array($type, ['photo', 'hint', 'code'])) {
            return [
                'status' => 'error',
                'message' => 'Invalid type. Use: photo, hint, or code',
                'code' => 400
            ];
        }

        // Type-specific validation
        if ($type === 'photo' && empty($data['photo_data'])) {
            return [
                'status' => 'error',
                'message' => 'Photo data is required for photo type',
                'code' => 400
            ];
        }

        if ($type === 'hint' && empty($data['hint_text'])) {
            return [
                'status' => 'error',
                'message' => 'Hint text is required for hint type',
                'code' => 400
            ];
        }

        if ($type === 'code' && empty($data['code'])) {
            return [
                'status' => 'error',
                'message' => 'Code is required for code type',
                'code' => 400
            ];
        }

        // For photo type, verify with AI immediately
        if ($type === 'photo') {
            $aiResult = $this->aiService->verifyEntrancePhoto(
                $data['photo_data'],
                $addressId
            );

            if (!$aiResult['success']) {
                // AI verification failed
                return [
                    'status' => 'rejected',
                    'message' => 'Photo verification failed',
                    'reason' => $aiResult['reason'] ?? 'AI verification failed',
                    'details' => $aiResult['details'] ?? '',
                    'code' => 400
                ];
            }

            // Check if valid entrance
            if (!$aiResult['is_valid']) {
                return [
                    'status' => 'rejected',
                    'message' => 'Photo does not show a valid entrance',
                    'details' => $aiResult['details'],
                    'confidence' => $aiResult['confidence'],
                    'code' => 400
                ];
            }

            // Valid entrance - create contribution
            $contributionId = $this->contributionModel->create([
                'user_id' => $userId,
                'address_id' => $addressId,
                'type' => $type,
                'status' => 'verified', // Immediately verified by AI
                'points' => $aiResult['points_earned']
            ]);

            // Save photo
            $photoUrl = $this->savePhotoToStorage($data['photo_data'], $contributionId);
            
            $this->contributionModel->addPhoto($contributionId, [
                'photo_url' => $photoUrl,
                'entrance_number' => $data['entrance_number'] ?? null
            ]);

            // Award points to user
            $user = $this->userModel->findById($userId);
            $multiplier = (float)$user['multiplier'];
            $finalPoints = (int)($aiResult['points_earned'] * $multiplier);

            $this->userModel->updateBalance($userId, $finalPoints);
            $this->userModel->incrementWeeklyContributions($userId);

            // Record points history
            $this->contributionModel->recordPoints(
                $userId,
                $contributionId,
                $finalPoints,
                $multiplier,
                "Фото входа подтверждено AI"
            );

            return [
                'status' => 'success',
                'message' => 'Photo verified and contribution created',
                'data' => [
                    'contribution_id' => $contributionId,
                    'points_earned' => $finalPoints,
                    'multiplier_applied' => $multiplier,
                    'new_balance' => (int)$user['balance'] + $finalPoints,
                    'ai_confidence' => $aiResult['confidence'],
                    'from_cache' => $aiResult['from_cache']
                ],
                'code' => 201
            ];
        }

        // For hint and code types, create without AI verification
        $contributionId = $this->contributionModel->create([
            'user_id' => $userId,
            'address_id' => $addressId,
            'type' => $type,
            'status' => 'verified', // Auto-verify hints and codes
            'points' => $this->estimatePoints($type)
        ]);

        if ($type === 'hint') {
            $this->contributionModel->addHint($contributionId, $data['hint_text']);
        } elseif ($type === 'code') {
            $this->contributionModel->addCode($addressId, [
                'code' => $data['code'],
                'entrance_number' => $data['entrance_number'] ?? null,
                'gate_number' => $data['gate_number'] ?? null
            ]);
        }

        // Award points
        $user = $this->userModel->findById($userId);
        $multiplier = (float)$user['multiplier'];
        $points = $this->estimatePoints($type);
        $finalPoints = (int)($points * $multiplier);

        $this->userModel->updateBalance($userId, $finalPoints);
        $this->userModel->incrementWeeklyContributions($userId);

        $this->contributionModel->recordPoints(
            $userId,
            $contributionId,
            $finalPoints,
            $multiplier,
            ucfirst($type) . " добавлен"
        );

        return [
            'status' => 'success',
            'message' => 'Contribution created successfully',
            'data' => [
                'contribution_id' => $contributionId,
                'points_earned' => $finalPoints,
                'multiplier_applied' => $multiplier,
                'new_balance' => (int)$user['balance'] + $finalPoints
            ],
            'code' => 201
        ];
    }

    /**
     * Save photo to storage
     * In production, use S3 or similar
     */
    private function savePhotoToStorage($base64Data, $contributionId)
    {
        // For MVP, save to local storage
        $uploadDir = '/var/www/html/storage/uploads/';
        
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $filename = 'contribution_' . $contributionId . '_' . time() . '.jpg';
        $filepath = $uploadDir . $filename;

        // Decode and save
        $imageData = base64_decode($base64Data);
        file_put_contents($filepath, $imageData);

        // Return relative URL
        return '/storage/uploads/' . $filename;
    }

    /**
     * Estimate points for contribution type
     */
    private function estimatePoints($type)
    {
        $points = [
            'photo' => 10,
            'hint' => 5,
            'code' => 15
        ];

        return $points[$type] ?? 0;
    }

    // ... rest of the methods remain the same
}