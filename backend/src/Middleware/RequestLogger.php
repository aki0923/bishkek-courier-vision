<?php

namespace App\Middleware;

class RequestLogger
{
    private static $startTime;

    public static function start()
    {
        self::$startTime = microtime(true);
    }

    public static function end($response = null)
    {
        $duration = (microtime(true) - self::$startTime) * 1000; // ms

        $logEntry = sprintf(
            "[%s] %s %s - %dms - Code: %d",
            date('Y-m-d H:i:s'),
            $_SERVER['REQUEST_METHOD'],
            $_SERVER['REQUEST_URI'],
            $duration,
            http_response_code() ?: 200
        );

        // Log slow requests
        if ($duration > 1000) {
            $logEntry .= " [SLOW REQUEST]";
        }

        error_log($logEntry);
    }
}