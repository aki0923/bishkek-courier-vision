<?php

namespace App\Controllers;

use App\Database;
use App\Models\User;
use App\Models\Contribution;

class ProfileController
{
    private $db;
    private $userModel;
    private $contributionModel;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->userModel = new User($this->db);
        $this->contributionModel = new Contribution($this->db);
    }

    /**
     * Get user profile with statistics
     * GET /api/profile
     */
    public function getProfile($userId)
    {
        $user = $this->userModel->findById($userId);

        if (!$user) {
            return [
                'status' => 'error',
                'message' => 'User not found',
                'code' => 404
            ];
        }

        // Get statistics
        $stats = $this->getStatistics($userId);

        // Get recent contributions
        $recentContributions = $this->contributionModel->getByUserId($userId, 10);

        // Calculate weekly goal progress
        $weeklyGoal = $this->calculateWeeklyGoal($user['weekly_contributions']);

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
                    'status' => $user['status'],
                    'member_since' => $user['created_at']
                ],
                'statistics' => $stats,
                'weekly_goal' => $weeklyGoal,
                'recent_contributions' => $recentContributions
            ],
            'code' => 200
        ];
    }

    /**
     * Get contribution history
     * GET /api/profile/history
     */
    public function getHistory($userId, $params = [])
    {
        $limit = $params['limit'] ?? 20;
        $offset = $params['offset'] ?? 0;

        $history = $this->contributionModel->getByUserId($userId, $limit, $offset);
        $total = $this->contributionModel->countByUserId($userId);

        return [
            'status' => 'success',
            'data' => $history,
            'pagination' => [
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset,
                'has_more' => ($offset + $limit) < $total
            ],
            'code' => 200
        ];
    }

    /**
     * Get statistics
     */
    private function getStatistics($userId)
    {
        $sql = "SELECT 
                    COUNT(*) as total_contributions,
                    SUM(CASE WHEN type = 'photo' THEN 1 ELSE 0 END) as photos_count,
                    SUM(CASE WHEN type = 'hint' THEN 1 ELSE 0 END) as hints_count,
                    SUM(CASE WHEN type = 'code' THEN 1 ELSE 0 END) as codes_count,
                    SUM(CASE WHEN status = 'verified' THEN 1 ELSE 0 END) as verified_count,
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_count
                FROM contributions
                WHERE user_id = ?";
        
        $stats = $this->db->fetch($sql, [$userId]);

        // Get total points earned
        $pointsSql = "SELECT SUM(points_earned) as total_points 
                      FROM points_history 
                      WHERE user_id = ?";
        $points = $this->db->fetch($pointsSql, [$userId]);

        return [
            'total_contributions' => (int)$stats['total_contributions'],
            'photos_submitted' => (int)$stats['photos_count'],
            'hints_shared' => (int)$stats['hints_count'],
            'codes_added' => (int)$stats['codes_count'],
            'verified_contributions' => (int)$stats['verified_count'],
            'pending_review' => (int)$stats['pending_count'],
            'total_points_earned' => (int)($points['total_points'] ?? 0)
        ];
    }

    /**
     * Calculate weekly goal progress
     */
    private function calculateWeeklyGoal($weeklyContributions)
    {
        $goals = [
            ['target' => 5, 'multiplier' => 1.2, 'status' => 'Помощник'],
            ['target' => 10, 'multiplier' => 1.5, 'status' => 'Эксперт'],
            ['target' => 20, 'multiplier' => 2.0, 'status' => 'Мастер']
        ];

        $currentGoal = null;
        $achieved = [];

        foreach ($goals as $goal) {
            if ($weeklyContributions >= $goal['target']) {
                $achieved[] = $goal;
            } else {
                $currentGoal = $goal;
                break;
            }
        }

        if (!$currentGoal && !empty($achieved)) {
            // All goals achieved
            $lastGoal = end($achieved);
            return [
                'current_count' => $weeklyContributions,
                'target' => $lastGoal['target'],
                'progress_percent' => 100,
                'multiplier_active' => $lastGoal['multiplier'],
                'status' => $lastGoal['status'],
                'message' => 'Все цели выполнены! 🎉',
                'all_achieved' => true
            ];
        }

        if ($currentGoal) {
            return [
                'current_count' => $weeklyContributions,
                'target' => $currentGoal['target'],
                'progress_percent' => round(($weeklyContributions / $currentGoal['target']) * 100),
                'multiplier_target' => $currentGoal['multiplier'],
                'status_target' => $currentGoal['status'],
                'remaining' => $currentGoal['target'] - $weeklyContributions,
                'message' => "До множителя x{$currentGoal['multiplier']} осталось " . 
                           ($currentGoal['target'] - $weeklyContributions) . " вкладов",
                'all_achieved' => false
            ];
        }

        // No contributions yet
        return [
            'current_count' => 0,
            'target' => 5,
            'progress_percent' => 0,
            'multiplier_target' => 1.2,
            'status_target' => 'Помощник',
            'remaining' => 5,
            'message' => 'Начните делиться информацией для получения бонуса!',
            'all_achieved' => false
        ];
    }
}