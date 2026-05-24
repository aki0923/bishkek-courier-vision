<?php

namespace App\Models;

use App\Database;

class Address
{
    private $db;
    private static $cache = []; // In-memory cache
    private static $cacheExpiry = 300; // 5 minutes

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    /**
     * Find nearby addresses with optimized Haversine and caching
     */
    public function findNearby($lat, $lng, $radiusMeters = 2000)
    {
        $cacheKey = "nearby_{$lat}_{$lng}_{$radiusMeters}";
        
        // Check cache
        if (isset(self::$cache[$cacheKey])) {
            $cached = self::$cache[$cacheKey];
            if (time() - $cached['time'] < self::$cacheExpiry) {
                return $cached['data'];
            }
        }

        // Use bounding box first for efficiency (much faster than Haversine on all)
        $radiusDegrees = $radiusMeters / 111320;
        
        $minLat = $lat - $radiusDegrees;
        $maxLat = $lat + $radiusDegrees;
        $minLng = $lng - $radiusDegrees;
        $maxLng = $lng + $radiusDegrees;

        $sql = "SELECT a.*,
                (6371000 * acos(
                    cos(radians(?)) * cos(radians(a.latitude)) *
                    cos(radians(a.longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(a.latitude))
                )) AS distance,
                (SELECT COUNT(*) FROM entrance_photos ep 
                 JOIN contributions c ON ep.contribution_id = c.id 
                 WHERE c.address_id = a.id AND c.status = 'verified') as photos_count,
                (SELECT COUNT(*) FROM intercom_codes ic 
                 WHERE ic.address_id = a.id AND ic.is_active = 1) as codes_count
                FROM addresses a
                WHERE a.latitude BETWEEN ? AND ?
                  AND a.longitude BETWEEN ? AND ?
                HAVING distance < ?
                ORDER BY distance
                LIMIT 20";
        
        $result = $this->db->fetchAll($sql, [
            $lat, $lng, $lat,
            $minLat, $maxLat,
            $minLng, $maxLng,
            $radiusMeters
        ]);

        // Cache result
        self::$cache[$cacheKey] = [
            'time' => time(),
            'data' => $result
        ];

        return $result;
    }

    /**
     * Find address by ID with related data in one query
     */
    public function findByIdWithDetails($id)
    {
        $sql = "SELECT a.*,
                (SELECT COUNT(*) FROM contributions WHERE address_id = a.id) as total_contributions
                FROM addresses a
                WHERE a.id = ?
                LIMIT 1";
        
        return $this->db->fetch($sql, [$id]);
    }

    /**
     * Optimized photos query with user info
     */
    public function getEntrancePhotos($addressId)
    {
        $sql = "SELECT 
                    ep.id,
                    ep.photo_url,
                    ep.entrance_number,
                    ep.ai_verified,
                    c.created_at as uploaded_at,
                    u.courier_id,
                    u.status as courier_status
                FROM entrance_photos ep
                JOIN contributions c ON ep.contribution_id = c.id
                JOIN users u ON c.user_id = u.id
                WHERE c.address_id = ? 
                  AND c.status = 'verified'
                ORDER BY ep.created_at DESC
                LIMIT 10";
        
        return $this->db->fetchAll($sql, [$addressId]);
    }

    /**
     * Get statistics for address
     */
    public function getStatistics($addressId)
    {
        $sql = "SELECT 
                    COUNT(DISTINCT c.id) as total_contributions,
                    COUNT(DISTINCT CASE WHEN c.type = 'photo' THEN c.id END) as photos,
                    COUNT(DISTINCT CASE WHEN c.type = 'code' THEN c.id END) as codes,
                    COUNT(DISTINCT CASE WHEN c.type = 'hint' THEN c.id END) as hints,
                    COUNT(DISTINCT c.user_id) as unique_contributors
                FROM contributions c
                WHERE c.address_id = ? AND c.status = 'verified'";
        
        return $this->db->fetch($sql, [$addressId]);
    }

    /**
     * Clear cache
     */
    public static function clearCache()
    {
        self::$cache = [];
    }
}