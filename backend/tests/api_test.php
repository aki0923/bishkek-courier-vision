<?php

/**
 * Simple API tests
 * Run: php tests/api_test.php
 */

class ApiTester
{
    private $baseUrl;
    private $token;
    private $passed = 0;
    private $failed = 0;

    public function __construct($baseUrl = 'http://localhost:8000/api')
    {
        $this->baseUrl = $baseUrl;
    }

    public function run()
    {
        echo "🧪 Running API Tests...\n\n";

        $this->testHealthCheck();
        $this->testLogin();
        $this->testGetAddresses();
        $this->testGetNearbyAddresses();
        $this->testGetAddressDetails();
        $this->testSearchAddresses();
        $this->testGetProfile();
        $this->testCreateContribution();

        $this->printSummary();
    }

    private function testHealthCheck()
    {
        $response = $this->get('/health');
        $this->assert($response['status'] === 'healthy', 'Health check');
    }

    private function testLogin()
    {
        $response = $this->post('/auth/login', [
            'courier_id' => '4821',
            'aggregator' => 'yandex_pro'
        ]);

        $this->assert($response['status'] === 'success', 'Login successful');
        $this->assert(isset($response['data']['token']), 'Token received');
        
        if (isset($response['data']['token'])) {
            $this->token = $response['data']['token'];
        }
    }

    private function testGetAddresses()
    {
        $response = $this->get('/addresses');
        $this->assert($response['status'] === 'success', 'Get all addresses');
        $this->assert(is_array($response['data']), 'Addresses is array');
        $this->assert(count($response['data']) > 0, 'Has addresses');
    }

    private function testGetNearbyAddresses()
    {
        $response = $this->get('/addresses/nearby?lat=42.8746&lng=74.5698&radius=2000');
        $this->assert($response['status'] === 'success', 'Get nearby addresses');
        $this->assert(isset($response['center']), 'Has center coordinates');
    }

    private function testGetAddressDetails()
    {
        $response = $this->get('/addresses/1');
        $this->assert($response['status'] === 'success', 'Get address details');
        $this->assert(isset($response['data']['address']), 'Has address data');
        $this->assert(isset($response['data']['intercom_codes']), 'Has intercom codes');
    }

    private function testSearchAddresses()
    {
        $response = $this->get('/addresses/search?q=Асанбай');
        $this->assert($response['status'] === 'success', 'Search addresses');
        $this->assert(count($response['data']) > 0, 'Found Asanbay addresses');
    }

    private function testGetProfile()
    {
        if (!$this->token) {
            $this->skip('Get profile (no token)');
            return;
        }

        $response = $this->get('/profile', true);
        $this->assert($response['status'] === 'success', 'Get profile');
        $this->assert(isset($response['data']['user']), 'Has user data');
        $this->assert(isset($response['data']['statistics']), 'Has statistics');
    }

    private function testCreateContribution()
    {
        if (!$this->token) {
            $this->skip('Create contribution (no token)');
            return;
        }

        $response = $this->post('/contributions', [
            'address_id' => 1,
            'type' => 'hint',
            'hint_text' => 'Тестовая подсказка от автотестов'
        ], true);

        $this->assert($response['status'] === 'success', 'Create hint contribution');
        $this->assert(isset($response['data']['contribution_id']), 'Got contribution ID');
    }

    private function get($endpoint, $auth = false)
    {
        return $this->request('GET', $endpoint, null, $auth);
    }

    private function post($endpoint, $data, $auth = false)
    {
        return $this->request('POST', $endpoint, $data, $auth);
    }

    private function request($method, $endpoint, $data = null, $auth = false)
    {
        $url = $this->baseUrl . $endpoint;
        $ch = curl_init($url);

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        
        $headers = ['Content-Type: application/json'];
        if ($auth && $this->token) {
            $headers[] = 'Authorization: Bearer ' . $this->token;
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }

        $response = curl_exec($ch);
        curl_close($ch);

        return json_decode($response, true);
    }

    private function assert($condition, $message)
    {
        if ($condition) {
            echo "✅ $message\n";
            $this->passed++;
        } else {
            echo "❌ $message\n";
            $this->failed++;
        }
    }

    private function skip($message)
    {
        echo "⏭️  Skipped: $message\n";
    }

    private function printSummary()
    {
        $total = $this->passed + $this->failed;
        $rate = $total > 0 ? ($this->passed / $total * 100) : 0;

        echo "\n";
        echo str_repeat("=", 40) . "\n";
        echo "Results: $this->passed/$total passed (" . number_format($rate, 1) . "%)\n";
        echo str_repeat("=", 40) . "\n";

        if ($this->failed === 0) {
            echo "\n🎉 All tests passed!\n";
            exit(0);
        } else {
            echo "\n⚠️  Some tests failed.\n";
            exit(1);
        }
    }
}

$tester = new ApiTester();
$tester->run();