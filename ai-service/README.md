# AI Service - Bishkek Courier Vision

AI-powered image verification using **Groq's Llama 4 Scout** model.

## Architecture

Request → Flask API → Groq Client → Llama 4 Scout (Vision)  
↓  
Cache Layer (in-memory)  
↓  
Logger & Statistics  

## Quick Start

### 1. Get Free Groq API Key

1. Visit https://console.groq.com
2. Sign up (completely free)
3. Generate API key
4. Free tier includes 30 requests/minute

### 2. Install & Configure

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env: add GROQ_API_KEY=your_key
```

### 3. Run Service

```bash
# Development mode
python app.py

# Production mode
gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 app:app

# Docker
docker build -t bcv-ai-service .
docker run -p 5000:5000 --env-file .env bcv-ai-service
```

## API Endpoints

### `POST /ai/verify-entrance`

Verify if image shows a valid building entrance.

**Request:**
```json
{
  "image": "base64_encoded_image",
  "address_id": 123
}
```

**Response (Success):**
```json
{
  "status": "success",
  "is_valid_entrance": true,
  "confidence": 0.95,
  "entrance_type": "main_entrance",
  "visible_features": ["door", "intercom", "numbers"],
  "details": "Main entrance with intercom and apartment numbers",
  "points_earned": 15,
  "from_cache": false,
  "ai_metadata": {
    "provider": "Groq",
    "model": "meta-llama/llama-4-scout-17b-16e-instruct",
    "tokens_used": 245
  }
}
```

**Response (Rejected):**
```json
{
  "status": "rejected",
  "reason": "spam",
  "is_valid_entrance": false,
  "confidence": 0.92,
  "details": "Image is a meme, not a real entrance",
  "points_earned": 0
}
```

### `POST /ai/verify-batch`

Verify multiple images in one request (max 10).

**Request:**
```json
{
  "images": [
    {"id": "1", "image": "base64...", "address_id": 1},
    {"id": "2", "image": "base64...", "address_id": 2}
  ]
}
```

### `POST /ai/check-spam`

Standalone spam detection.

### `GET /ai/health`

Service health check.

### `GET /ai/statistics`

Get usage statistics and cache hit rate.

## Configuration

Edit `config.py` or `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `GROQ_API_KEY` | Your Groq API key | Required |
| `GROQ_MODEL` | Model name | `meta-llama/llama-4-scout-17b-16e-instruct` |
| `MIN_CONFIDENCE_THRESHOLD` | Min confidence for valid | 0.70 |
| `MAX_IMAGE_SIZE_MB` | Max upload size | 10 |
| `CACHE_TTL_SECONDS` | Cache duration | 3600 |

## Performance

- **Average response time**: <2 seconds (Groq is super fast)
- **Cache hit rate**: ~60% in typical usage
- **Free tier**: 30 requests/minute
- **Image processing**: Auto-resize to 2048px for optimal speed

## Testing

```bash
# Run tests
pytest tests/

# Test with coverage
pytest tests/ --cov=. --cov-report=html

# Manual API test
curl -X POST http://localhost:5000/ai/verify-entrance \
  -H "Content-Type: application/json" \
  -d '{"image":"base64_image_data"}'
```

## Troubleshooting

### "GROQ_API_KEY not configured"
- Check `.env` file has `GROQ_API_KEY=your_key`
- Verify key at https://console.groq.com

### Slow responses
- Check Groq status: https://status.groq.com
- Verify your free tier limits
- Use caching for repeated queries

### Inconsistent results
- Adjust `temperature` in code (lower = more consistent)
- Check `MIN_CONFIDENCE_THRESHOLD`
- Review prompts in `prompts/entrance_verification.py`

## Production Considerations

- [ ] Use Redis for distributed caching
- [ ] Implement rate limiting per user
- [ ] Add Sentry for error tracking
- [ ] Monitor Groq usage limits
- [ ] Add proper image hashing for duplicate detection
- [ ] Implement async processing for batch requests