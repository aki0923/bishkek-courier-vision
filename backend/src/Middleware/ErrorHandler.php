<?php

namespace App\Middleware;

use Exception;
use Throwable;

class ErrorHandler
{
    /**
     * Register global error handler
     */
    public static function register()
    {
        set_error_handler([self::class, 'handleError']);
        set_exception_handler([self::class, 'handleException']);
        register_shutdown_function([self::class, 'handleShutdown']);
    }

    /**
     * Handle PHP errors
     */
    public static function handleError($severity, $message, $file, $line)
    {
        if (!(error_reporting() & $severity)) {
            return;
        }

        $errorTypes = [
            E_ERROR => 'Error',
            E_WARNING => 'Warning',
            E_PARSE => 'Parse Error',
            E_NOTICE => 'Notice',
            E_USER_ERROR => 'User Error',
            E_USER_WARNING => 'User Warning',
        ];

        $errorType = $errorTypes[$severity] ?? 'Unknown';

        self::logError([
            'type' => $errorType,
            'message' => $message,
            'file' => $file,
            'line' => $line,
            'severity' => $severity
        ]);

        if (in_array($severity, [E_ERROR, E_USER_ERROR, E_PARSE])) {
            self::sendErrorResponse('Internal Server Error', 500);
        }
    }

    /**
     * Handle uncaught exceptions
     */
    public static function handleException(Throwable $exception)
    {
        self::logError([
            'type' => 'Exception',
            'class' => get_class($exception),
            'message' => $exception->getMessage(),
            'file' => $exception->getFile(),
            'line' => $exception->getLine(),
            'trace' => $exception->getTraceAsString()
        ]);

        $code = self::getHttpCodeFromException($exception);
        $message = $exception->getMessage();

        // Don't expose internal errors in production
        if ($code === 500 && ($_ENV['APP_ENV'] ?? 'production') === 'production') {
            $message = 'Internal Server Error';
        }

        self::sendErrorResponse($message, $code);
    }

    /**
     * Handle shutdown errors (fatal errors)
     */
    public static function handleShutdown()
    {
        $error = error_get_last();
        
        if ($error !== null && in_array($error['type'], [E_ERROR, E_PARSE, E_COMPILE_ERROR])) {
            self::logError([
                'type' => 'Fatal Error',
                'message' => $error['message'],
                'file' => $error['file'],
                'line' => $error['line']
            ]);

            if (!headers_sent()) {
                self::sendErrorResponse('Internal Server Error', 500);
            }
        }
    }

    /**
     * Get appropriate HTTP code from exception
     */
    private static function getHttpCodeFromException(Throwable $exception)
    {
        $code = $exception->getCode();
        
        // Use exception code if it's a valid HTTP code
        if ($code >= 400 && $code < 600) {
            return $code;
        }

        // Map common exceptions
        $exceptionMap = [
            'InvalidArgumentException' => 400,
            'UnauthorizedException' => 401,
            'NotFoundException' => 404,
            'ValidationException' => 422,
        ];

        $className = (new \ReflectionClass($exception))->getShortName();
        return $exceptionMap[$className] ?? 500;
    }

    /**
     * Log error to file
     */
    private static function logError($error)
    {
        $logFile = '/var/log/apache2/app_errors.log';
        $logEntry = sprintf(
            "[%s] %s: %s in %s on line %d\n",
            date('Y-m-d H:i:s'),
            $error['type'] ?? 'Error',
            $error['message'] ?? 'Unknown error',
            $error['file'] ?? 'unknown',
            $error['line'] ?? 0
        );

        if (isset($error['trace'])) {
            $logEntry .= "Trace: " . $error['trace'] . "\n";
        }

        error_log($logEntry, 3, $logFile);
    }

    /**
     * Send error response
     */
    private static function sendErrorResponse($message, $code = 500)
    {
        if (!headers_sent()) {
            http_response_code($code);
            header('Content-Type: application/json');
        }

        echo json_encode([
            'status' => 'error',
            'message' => $message,
            'code' => $code,
            'timestamp' => date('Y-m-d H:i:s')
        ]);

        exit;
    }
}