<?php

namespace App\Models;

use App\Database;

class Address
{
    private $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    /**
     * Find all addresses
     */
    public function findAll($limit = 50, $offset = 0)
    {
        $sql = "SELECT * FROM addresses 
                ORDER BY created_at DESC 
                LIMIT ? OFFSET ?";
        
        return $this->db->fetchAll($sql, [$limit, $offset]);
    }

    /**
     * Find address by ID
     */
    public function findById($id)
    {
        $sql = "SELECT * FROM addresses WHERE id = ? LIMIT 1";
        return $this->db->fetch($sql, [$id]);
    }

    /**
     * Find nearby addresses using Haversine formula
     */
    public function findNearby($lat, $lng, $radiusMeters = 2000)
    {
        // Convert radius to degrees (approximate)
        $radiusDegrees = $radiusMeters / 111320; // 1 degree ≈ 111.32 km

        $sql = "SELECT *,
                (6371000 * acos(
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                )) AS distance
                FROM addresses
                HAVING distance < ?
                ORDER BY distance
                LIMIT 20";
        
        return $this->db->fetchAll($sql, [$lat, $lng, $lat, $radiusMeters]);
    }

    /**
     * Search addresses by name or address
     */
    public function search($query)
    {
        $searchTerm = "%{$query}%";
        
        $sql = "SELECT * FROM addresses 
                WHERE name LIKE ? OR address LIKE ?
                ORDER BY name
                LIMIT 20";
        
        return $this->db->fetchAll($sql, [$searchTerm, $searchTerm]);
    }

    /**
     * Get entrance photos for address
     */
    public function getEntrancePhotos($addressId)
    {
        $sql = "SELECT ep.*, c.user_id, c.created_at as uploaded_at
                FROM entrance_photos ep
                JOIN contributions c ON ep.contribution_id = c.id
                WHERE c.address_id = ? AND c.status = 'verified'
                ORDER BY ep.created_at DESC
                LIMIT 10";
        
        return $this->db->fetchAll($sql, [$addressId]);
    }

    /**
     * Get intercom codes for address
     */
    public function getIntercomCodes($addressId)
    {
        $sql = "SELECT * FROM intercom_codes 
                WHERE address_id = ? AND is_active = 1
                ORDER BY verified_count DESC, created_at DESC";
        
        return $this->db->fetchAll($sql, [$addressId]);
    }

    /**
     * Get hints for address
     */
    public function getHints($addressId)
    {
        $sql = "SELECT h.*, c.user_id, c.created_at
                FROM hints h
                JOIN contributions c ON h.contribution_id = c.id
                WHERE c.address_id = ? AND c.status = 'verified'
                ORDER BY h.helpful_count DESC, c.created_at DESC
                LIMIT 5";
        
        return $this->db->fetchAll($sql, [$addressId]);
    }

    /**
     * Create new address
     */
    public function create($data)
    {
        $sql = "INSERT INTO addresses (
                    name, address, latitude, longitude,
                    building_type, total_entrances, has_security
                ) VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        $this->db->query($sql, [
            $data['name'],
            $data['address'],
            $data['latitude'],
            $data['longitude'],
            $data['building_type'] ?? 'residential',
            $data['total_entrances'] ?? 1,
            $data['has_security'] ?? false
        ]);

        return $this->db->getConnection()->lastInsertId();
    }
}