"""
Tests for Groq Vision API integration
Run: pytest tests/
"""

import pytest
import json
import base64
import os
from app import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def sample_image_base64():
    """Load a sample test image"""
    # Create a small test image
    from PIL import Image
    import io
    
    img = Image.new('RGB', (500, 500), color='gray')
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG')
    return base64.b64encode(buffer.getvalue()).decode('utf-8')


def test_health_check(client):
    """Test service health"""
    response = client.get('/ai/health')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert data['status'] == 'healthy'
    assert 'groq_configured' in data
    assert data['model'] == 'meta-llama/llama-4-scout-17b-16e-instruct'


def test_root_endpoint(client):
    """Test root endpoint shows correct info"""
    response = client.get('/')
    data = json.loads(response.data)
    
    assert data['ai_provider'] == 'Groq'
    assert 'meta-llama/llama-4-scout' in data['model']


def test_verify_entrance_missing_image(client):
    """Test entrance verification without image"""
    response = client.post('/ai/verify-entrance', json={})
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert data['status'] == 'error'


def test_spam_check_missing_image(client):
    """Test spam check without image"""
    response = client.post('/ai/check-spam', json={})
    
    assert response.status_code == 400


def test_batch_verification_empty(client):
    """Test batch endpoint with empty array"""
    response = client.post('/ai/verify-batch', json={'images': []})
    
    assert response.status_code == 400


def test_batch_verification_too_many(client, sample_image_base64):
    """Test batch endpoint with too many images"""
    images = [
        {'id': str(i), 'image': sample_image_base64}
        for i in range(15)
    ]
    
    response = client.post('/ai/verify-batch', json={'images': images})
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'Maximum 10' in data['message']


@pytest.mark.skipif(
    not os.getenv('GROQ_API_KEY'),
    reason="GROQ_API_KEY not set"
)
def test_real_groq_call(client, sample_image_base64):
    """Test with real Groq API call (requires API key)"""
    response = client.post(
        '/ai/verify-entrance',
        json={'image': sample_image_base64}
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'is_valid_entrance' in data
    assert 'confidence' in data
    assert data['ai_metadata']['provider'] == 'Groq'


def test_statistics_endpoint(client):
    """Test statistics endpoint"""
    response = client.get('/ai/statistics')
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['ai_provider'] == 'Groq Llama 4 Scout'
    assert 'cache' in data