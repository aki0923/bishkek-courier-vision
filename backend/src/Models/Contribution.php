<?php

namespace App\Models;

use App\Database;

class Contribution
{
    private $db;
    private $connection;

    public function __construct(Database $db)
    {
        $this->db = $db;
        $this->connection = $db->getConnection();
    }

    public function create($data)
    {
        $sql = "INSERT INTO contributions (
                    user_id, address_id, type, status, points
                ) VALUES (?, ?, ?, ?, ?)";
        
        $this->db->query($sql, [
            $data['user_id'],
            $data['address_id'],
            $data['type'],
            $data['status'] ?? 'pending',
            $data['points'] ?? 0
        ]);

        return $this->connection->lastInsertId();
    }

    public function findById($id)
    {
        $sql = "SELECT c.*, a.name as address_name, a.address, u.courier_id
                FROM contributions c
                JOIN addresses a ON c.address_id = a.id
                JOIN users u ON c.user_id = u.id
                WHERE c.id = ? LIMIT 1";
        
        return $this->db->fetch($sql, [$id]);
    }

    public function updateStatus($id, $status, $points = 0, $aiConfidence = null)
    {
        $sql = "UPDATE contributions 
                SET status = ?, points = ?, ai_confidence = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?";
        
        $this->db->query($sql, [$status, $points, $aiConfidence, $id]);
    }

    public function getByUserId($userId, $limit = 20, $offset = 0)
    {
        $sql = "SELECT c.*, a.name as address_name, a.address
                FROM contributions c
                JOIN addresses a ON c.address_id = a.id
                WHERE c.user_id = ?
                ORDER BY c.created_at DESC
                LIMIT ? OFFSET ?";
        
        return $this->db->fetchAll($sql, [$userId, $limit, $offset]);
    }

    public function countByUserId($userId)
    {
        $sql = "SELECT COUNT(*) as total FROM contributions WHERE user_id = ?";
        $result = $this->db->fetch($sql, [$userId]);
        return $result['total'] ?? 0;
    }

    public function addPhoto($contributionId, $data)
    {
        $sql = "INSERT INTO entrance_photos (
                    contribution_id, photo_url, entrance_number
                ) VALUES (?, ?, ?)";
        
        $this->db->query($sql, [
            $contributionId,
            $data['photo_url'],
            $data['entrance_number'] ?? null
        ]);
    }

    public function addHint($contributionId, $hintText)
    {
        $sql = "INSERT INTO hints (contribution_id, hint_text) 
                VALUES (?, ?)";
        
        $this->db->query($sql, [$contributionId, $hintText]);
    }

    public function addCode($addressId, $data)
    {
        $sql = "INSERT INTO intercom_codes (
                    address_id, code, entrance_number, gate_number
                ) VALUES (?, ?, ?, ?)";
        
        $this->db->query($sql, [
            $addressId,
            $data['code'],
            $data['entrance_number'] ?? null,
            $data['gate_number'] ?? null
        ]);
    }

    public function recordPoints($userId, $contributionId, $points, $multiplier, $reason)
    {
        $sql = "INSERT INTO points_history (
                    user_id, contribution_id, points_earned, 
                    multiplier_applied, reason
                ) VALUES (?, ?, ?, ?, ?)";
        
        $this->db->query($sql, [
            $userId,
            $contributionId,
            $points,
            $multiplier,
            $reason
        ]);
    }
}