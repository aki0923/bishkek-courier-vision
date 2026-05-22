"""
Simple tests for AI verification

Run with: python -m pytest tests/
"""

import pytest
import json
from app import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_check(client):
    """Test health check endpoint"""
    response = client.get('/ai/health')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert data['status'] == 'healthy'


def test_verify_entrance_missing_image(client):
    """Test entrance verification without image"""
    response = client.post(
        '/ai/verify-entrance',
        json={}
    )
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert data['status'] == 'error'


def test_spam_check_missing_image(client):
    """Test spam check without image"""
    response = client.post(
        '/ai/check-spam',
        json={}
    )
    
    assert response.status_code == 400


# Note: Full integration tests require OpenAI API key and real images
# These are smoke tests to ensure endpoints are working