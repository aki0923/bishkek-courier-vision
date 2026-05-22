<?php

namespace App\Controllers;

use App\Database;
use App\Models\Address;

class AddressController
{
    private $db;
    private $addressModel;

    public function __construct()
    {
        $this->db = Database::getInstance();
        $this->addressModel = new Address($this->db);
    }

    /**
     * Get all addresses
     * GET /api/addresses
     */
    public function getAll($params = [])
    {
        $limit = $params['limit'] ?? 50;
        $offset = $params['offset'] ?? 0;

        $addresses = $this->addressModel->findAll($limit, $offset);

        return [
            'status' => 'success',
            'data' => $addresses,
            'total' => count($addresses),
            'code' => 200
        ];
    }

    /**
     * Get nearby addresses
     * GET /api/addresses/nearby?lat=42.8746&lng=74.5698&radius=2000
     */
    public function getNearby($params)
    {
        $lat = $params['lat'] ?? 42.8746;  // Default to Bishkek center
        $lng = $params['lng'] ?? 74.5698;
        $radius = $params['radius'] ?? 2000; // 2km radius

        $addresses = $this->addressModel->findNearby($lat, $lng, $radius);

        return [
            'status' => 'success',
            'data' => $addresses,
            'center' => [
                'latitude' => (float)$lat,
                'longitude' => (float)$lng
            ],
            'radius_meters' => (int)$radius,
            'total' => count($addresses),
            'code' => 200
        ];
    }

    /**
     * Get address details by ID
     * GET /api/addresses/{id}
     */
    public function getById($id)
    {
        $address = $this->addressModel->findById($id);

        if (!$address) {
            return [
                'status' => 'error',
                'message' => 'Address not found',
                'code' => 404
            ];
        }

        // Get entrance photos
        $photos = $this->addressModel->getEntrancePhotos($id);

        // Get intercom codes
        $codes = $this->addressModel->getIntercomCodes($id);

        // Get hints
        $hints = $this->addressModel->getHints($id);

        return [
            'status' => 'success',
            'data' => [
                'address' => $address,
                'entrance_photos' => $photos,
                'intercom_codes' => $codes,
                'hints' => $hints,
                'total_contributions' => count($photos) + count($codes) + count($hints)
            ],
            'code' => 200
        ];
    }

    /**
     * Search addresses
     * GET /api/addresses/search?q=Асанбай
     */
    public function search($params)
    {
        $query = $params['q'] ?? '';

        if (empty($query)) {
            return [
                'status' => 'error',
                'message' => 'Search query is required',
                'code' => 400
            ];
        }

        $results = $this->addressModel->search($query);

        return [
            'status' => 'success',
            'data' => $results,
            'query' => $query,
            'total' => count($results),
            'code' => 200
        ];
    }
}