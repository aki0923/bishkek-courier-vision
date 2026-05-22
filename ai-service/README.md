# AI Service - Bishkek Courier Vision

AI-powered image verification service for entrance photos.

## Features

- Entrance verification using GPT-4 Vision
- Spam/meme detection
- Image quality validation
- Duplicate detection (basic MVP)

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY
```

### 3. Run Service

```bash
# Development
python app.py

# Production
gunicorn --bind 0.0.0.0:5000 app:app
```

### 4. Run with Docker

```bash
docker build -t bcv-ai-service .
docker run -p 5000:5000 --env-file .env bcv-ai-service
```

## API Endpoints

### POST /ai/verify-entrance

Verify if image shows a building entrance.

**Request:**
```json
{
  "image": "base64_encoded_image_data",
  "address_id": 123
}
```

**Response:**
```json
{
  "status": "success",
  "is_valid_entrance": true,
  "confidence": 0.95,
  "entrance_type": "main_entrance",
  "visible_features": ["intercom", "door", "numbers"],
  "details": "Clear photo of main entrance",
  "points_earned": 10
}
```

### POST /ai/check-spam

Check if image is spam or inappropriate.

**Request:**
```json
{
  "image": "base64_encoded_image_data"
}
```

**Response:**
```json
{
  "status": "success",
  "is_spam": false,
  "spam_type": "none",
  "confidence": 0.85,
  "reason": "Valid entrance photo"
}
```

### POST /ai/detect-duplicate

Check for duplicate images (MVP version).

## Testing

```bash
# Run tests
pytest tests/

# Test endpoint manually
curl -X POST http://localhost:5000/ai/health
```

## Configuration

Edit `config.py` or `.env`:

- `OPENAI_API_KEY`: Your OpenAI API key
- `MIN_CONFIDENCE_THRESHOLD`: Minimum confidence for valid entrance (default: 0.75)
- `MAX_IMAGE_SIZE_MB`: Maximum image size (default: 10MB)

## Cost Optimization

- Images are resized to max 2048px before sending to API
- JPEG compression at 85% quality
- Caching responses (TODO for production)

## Production Considerations

- [ ] Implement proper duplicate detection (image hashing)
- [ ] Add Redis caching for repeated images
- [ ] Rate limiting per user
- [ ] Async processing for batch uploads
- [ ] Monitor API costs and usage