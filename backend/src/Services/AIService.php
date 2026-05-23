<?php

namespace App\Services;

use Exception;

class AIService
{
    private $aiServiceUrl;

    public function __construct()
    {
        $this->aiServiceUrl = $_ENV['AI_SERVICE_URL'] ?? 'http://ai_service:5000';
    }

    /**
     * Verify entrance photo using AI service
     */
    public function verifyEntrancePhoto($imageData, $addressId = null)
    {
        $url = $this->aiServiceUrl . '/ai/verify-entrance';
        
        $data = [
            'image' => $imageData,
            'address_id' => $addressId
        ];

        try {
            $response = $this->makeRequest($url, $data);

            if ($response['status'] === 'success') {
                return [
                    'success' => true,
                    'is_valid' => $response['is_valid_entrance'],
                    'confidence' => $response['confidence'],
                    'entrance_type' => $response['entrance_type'] ?? 'unknown',
                    'visible_features' => $response['visible_features'] ?? [],
                    'details' => $response['details'] ?? '',
                    'points_earned' => $response['points_earned'] ?? 0,
                    'from_cache' => $response['from_cache'] ?? false
                ];
            }

            if ($response['status'] === 'rejected') {
                return [
                    'success' => false,
                    'reason' => $response['reason'] ?? 'unknown',
                    'details' => $response['details'] ?? 'AI verification failed'
                ];
            }

            throw new Exception('Unexpected AI service response');

        } catch (Exception $e) {
            error_log("AI Service Error: " . $e->getMessage());
            
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'fallback' => true
            ];
        }
    }

    /**
     * Check if image is spam
     */
    public function checkSpam($imageData)
    {
        $url = $this->aiServiceUrl . '/ai/check-spam';
        
        $data = [
            'image' => $imageData
        ];

        try {
            $response = $this->makeRequest($url, $data);

            if ($response['status'] === 'success') {
                return [
                    'is_spam' => $response['is_spam'],
                    'spam_type' => $response['spam_type'] ?? 'none',
                    'confidence' => $response['confidence'] ?? 0.0,
                    'reason' => $response['reason'] ?? ''
                ];
            }

            return [
                'is_spam' => false,
                'error' => 'AI service error'
            ];

        } catch (Exception $e) {
            error_log("Spam Check Error: " . $e->getMessage());
            
            // If AI service fails, don't block the upload
            return [
                'is_spam' => false,
                'fallback' => true
            ];
        }
    }

    /**
     * Get AI service health status
     */
    public function getHealth()
    {
        $url = $this->aiServiceUrl . '/ai/health';

        try {
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode === 200) {
                return [
                    'status' => 'healthy',
                    'url' => $this->aiServiceUrl
                ];
            }

            return [
                'status' => 'unhealthy',
                'code' => $httpCode
            ];

        } catch (Exception $e) {
            return [
                'status' => 'error',
                'message' => $e->getMessage()
            ];
        }
    }

    /**
     * Make HTTP request to AI service
     */
    private function makeRequest($url, $data)
    {
        $ch = curl_init($url);
        
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 120); // 2 minutes for AI processing
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json'
        ]);

        $response = curl_exec($ch);
        
        if (curl_errno($ch)) {
            $error = curl_error($ch);
            curl_close($ch);
            throw new Exception("cURL Error: $error");
        }

        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200) {
            throw new Exception("AI Service returned HTTP $httpCode");
        }

        $decoded = json_decode($response, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("Invalid JSON response from AI service");
        }

        return $decoded;
    }
}