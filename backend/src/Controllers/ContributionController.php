<?php

namespace App\Controllers;

use App\Database;
use App\Models\Contribution;
use App\Models\User;

class ContributionController
{
    private $db;
    private $contributionModel;
    private $userModel;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->contributionModel = new Contribution($this->db);
        $this->userModel = new User($this->db);
    }

    /**
     * Submit a new contribution
     * POST /api/contributions
     * 
     * Request: {
     *   "address_id": 1,
     *   "type": "photo|hint|code",
     *   "photo_url": "...",  // for photo type
     *   "hint_text": "...",  // for hint type
     *   "code": "123#4567",  // for code type
     *   "entrance_number": 2,
     *   "gate_number": "Калитка №2"
     * }
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
        if ($type === 'photo' && empty($data['photo_url'])) {
            return [
                'status' => 'error',
                'message' => 'Photo URL is required for photo type',
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

        // Create contribution (initially pending)
        $contributionId = $this->contributionModel->create([
            'user_id' => $userId,
            'address_id' => $addressId,
            'type' => $type,
            'status' => 'pending',
            'points' => 0  // Will be updated after AI verification
        ]);

        // Handle type-specific data
        if ($type === 'photo') {
            $this->contributionModel->addPhoto($contributionId, [
                'photo_url' => $data['photo_url'],
                'entrance_number' => $data['entrance_number'] ?? null
            ]);
        } elseif ($type === 'hint') {
            $this->contributionModel->addHint($contributionId, $data['hint_text']);
        } elseif ($type === 'code') {
            $this->contributionModel->addCode($addressId, [
                'code' => $data['code'],
                'entrance_number' => $data['entrance_number'] ?? null,
                'gate_number' => $data['gate_number'] ?? null
            ]);
        }

        // Get the full contribution data
        $contribution = $this->contributionModel->findById($contributionId);

        return [
            'status' => 'success',
            'message' => 'Contribution submitted successfully',
            'data' => [
                'contribution' => $contribution,
                'next_step' => 'Данные отправлены на проверку ИИ. Баллы будут начислены после подтверждения.',
                'estimated_points' => $this->estimatePoints($type)
            ],
            'code' => 201
        ];
    }

    /**
     * Verify contribution with AI result
     * PUT /api/contributions/{id}/verify
     * 
     * Called by AI service after verification
     */
    public function verify($contributionId, $data)
    {
        $contribution = $this->contributionModel->findById($contributionId);

        if (!$contribution) {
            return [
                'status' => 'error',
                'message' => 'Contribution not found',
                'code' => 404
            ];
        }

        $isValid = $data['is_valid'] ?? false;
        $confidence = $data['confidence'] ?? 0.0;
        $pointsEarned = $data['points_earned'] ?? 0;

        if ($isValid) {
            // Update contribution as verified
            $this->contributionModel->updateStatus(
                $contributionId,
                'verified',
                $pointsEarned,
                $confidence
            );

            // Update user balance
            $user = $this->userModel->findById($contribution['user_id']);
            $multiplier = (float)$user['multiplier'];
            $finalPoints = (int)($pointsEarned * $multiplier);

            $this->userModel->updateBalance($contribution['user_id'], $finalPoints);

            // Increment weekly contributions
            $this->userModel->incrementWeeklyContributions($contribution['user_id']);

            // Record points history
            $this->contributionModel->recordPoints(
                $contribution['user_id'],
                $contributionId,
                $finalPoints,
                $multiplier,
                "Вклад подтвержден ({$contribution['type']})"
            );

            return [
                'status' => 'success',
                'message' => 'Contribution verified and points awarded',
                'data' => [
                    'contribution_id' => $contributionId,
                    'points_earned' => $finalPoints,
                    'multiplier_applied' => $multiplier,
                    'new_balance' => (int)$user['balance'] + $finalPoints
                ],
                'code' => 200
            ];
        } else {
            // Reject contribution
            $this->contributionModel->updateStatus(
                $contributionId,
                'rejected',
                0,
                $confidence
            );

            return [
                'status' => 'success',
                'message' => 'Contribution rejected',
                'data' => [
                    'contribution_id' => $contributionId,
                    'reason' => $data['reason'] ?? 'AI verification failed'
                ],
                'code' => 200
            ];
        }
    }

    /**
     * Get user's contributions
     * GET /api/contributions?user_id={id}
     */
    public function getByUser($userId, $params = [])
    {
        $limit = $params['limit'] ?? 20;
        $offset = $params['offset'] ?? 0;

        $contributions = $this->contributionModel->getByUserId($userId, $limit, $offset);

        return [
            'status' => 'success',
            'data' => $contributions,
            'total' => count($contributions),
            'code' => 200
        ];
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
}