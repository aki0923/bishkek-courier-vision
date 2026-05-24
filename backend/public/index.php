<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Dotenv\Dotenv;
use App\Middleware\ErrorHandler;
use App\Middleware\RequestLogger;

// Register error handler first
ErrorHandler::register();

// Start request logging
RequestLogger::start();

// Load environment
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// ... rest of the existing code ...

// At the end:
RequestLogger::end();