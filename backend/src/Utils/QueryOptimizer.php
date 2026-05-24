<?php

namespace App\Utils;

use App\Database;

class QueryOptimizer
{
    /**
     * Add database indexes for better performance
     */
    public static function ensureIndexes()
    {
        $db = Database::getInstance();
        
        $indexes = [
            "CREATE INDEX IF NOT EXISTS idx_addresses_location 
             ON addresses(latitude, longitude)",
            
            "CREATE INDEX IF NOT EXISTS idx_contributions_address_status 
             ON contributions(address_id, status)",
            
            "CREATE INDEX IF NOT EXISTS idx_contributions_user_date 
             ON contributions(user_id, created_at DESC)",
            
            "CREATE INDEX IF NOT EXISTS idx_intercom_active 
             ON intercom_codes(address_id, is_active)",
            
            "CREATE INDEX IF NOT EXISTS idx_points_user_date 
             ON points_history(user_id, created_at DESC)",
        ];

        foreach ($indexes as $sql) {
            try {
                $db->query($sql);
            } catch (\Exception $e) {
                // Index might already exist
                error_log("Index creation warning: " . $e->getMessage());
            }
        }
    }

    /**
     * Analyze slow queries
     */
    public static function logSlowQuery($sql, $params, $duration)
    {
        if ($duration > 1.0) { // Queries taking more than 1 second
            error_log(sprintf(
                "SLOW QUERY (%.2fs): %s | Params: %s",
                $duration,
                $sql,
                json_encode($params)
            ));
        }
    }
}