<?php

namespace App\Models;

use App\Database;
use PDO;

class User
{
    private $db;
    private $connection;

    public function __construct(Database $db)
    {
        $this->db = $db;
        $this->connection = $db->getConnection();
    }

    /**
     * Find user by courier ID and aggregator
     */
    public function findByCourierId($courierId, $aggregator)
    {
        $sql = "SELECT * FROM users 
                WHERE courier_id = ? AND aggregator = ? 
                LIMIT 1";
        
        return $this->db->fetch($sql, [$courierId, $aggregator]);
    }

    /**
     * Find user by ID
     */
    public function findById($id)
    {
        $sql = "SELECT * FROM users WHERE id = ? LIMIT 1";
        return $this->db->fetch($sql, [$id]);
    }

    /**
     * Create new user
     */
    public function create($data)
    {
        $sql = "INSERT INTO users (
                    courier_id, aggregator, full_name, phone, 
                    balance, multiplier, weekly_contributions, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        $this->db->query($sql, [
            $data['courier_id'],
            $data['aggregator'],
            $data['full_name'] ?? null,
            $data['phone'] ?? null,
            $data['balance'] ?? 0,
            $data['multiplier'] ?? 1.00,
            $data['weekly_contributions'] ?? 0,
            $data['status'] ?? 'novice'
        ]);

        return $this->connection->lastInsertId();
    }

    /**
     * Update user balance and multiplier
     */
    public function updateBalance($userId, $points, $multiplier = null)
    {
        if ($multiplier !== null) {
            $sql = "UPDATE users 
                    SET balance = balance + ?, 
                        multiplier = ?,
                        updated_at = CURRENT_TIMESTAMP 
                    WHERE id = ?";
            $this->db->query($sql, [$points, $multiplier, $userId]);
        } else {
            $sql = "UPDATE users 
                    SET balance = balance + ?,
                        updated_at = CURRENT_TIMESTAMP 
                    WHERE id = ?";
            $this->db->query($sql, [$points, $userId]);
        }
    }

    /**
     * Increment weekly contributions
     */
    public function incrementWeeklyContributions($userId)
    {
        $sql = "UPDATE users 
                SET weekly_contributions = weekly_contributions + 1,
                    updated_at = CURRENT_TIMESTAMP 
                WHERE id = ?";
        
        $this->db->query($sql, [$userId]);

        // Check and update multiplier based on weekly goals
        $user = $this->findById($userId);
        $weeklyCount = $user['weekly_contributions'];

        $newMultiplier = 1.00;
        if ($weeklyCount >= 20) {
            $newMultiplier = 2.00;
        } elseif ($weeklyCount >= 10) {
            $newMultiplier = 1.50;
        } elseif ($weeklyCount >= 5) {
            $newMultiplier = 1.20;
        }

        if ($newMultiplier != $user['multiplier']) {
            $this->updateBalance($userId, 0, $newMultiplier);
        }
    }

    /**
     * Get points history
     */
    public function getPointsHistory($userId, $limit = 20)
    {
        $sql = "SELECT ph.*, a.name as address_name, a.address 
                FROM points_history ph
                LEFT JOIN contributions c ON ph.contribution_id = c.id
                LEFT JOIN addresses a ON c.address_id = a.id
                WHERE ph.user_id = ?
                ORDER BY ph.created_at DESC
                LIMIT ?";
        
        return $this->db->fetchAll($sql, [$userId, $limit]);
    }

    /**
     * Reset weekly contributions (should be run weekly)
     */
    public function resetWeeklyContributions()
    {
        $sql = "UPDATE users 
                SET weekly_contributions = 0,
                    multiplier = 1.00,
                    updated_at = CURRENT_TIMESTAMP";
        
        $this->db->query($sql);
    }
}