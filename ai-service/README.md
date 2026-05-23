# AI Service - Bishkek Courier Vision

AI-powered image verification using **Groq's Llama 4 Scout** model.

## Setup

### 1. Get Groq API Key

1. Go to https://console.groq.com
2. Sign up (free)
3. Create API key
4. Copy key to `.env`

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
cp .env.example .env
# Add your GROQ_API_KEY
```

### 4. Run Service

```bash
# Development
python app.py

# Production
gunicorn --bind 0.0.0.0:5000 app:app

# Docker
docker build -t bcv-ai-service .
docker run -p 5000:5000 --env-file .env bcv-ai-service
```

## API Endpoints

### POST /ai/verify-entrance

Verify if image shows a building entrance.

**Request:**
```json
{
  "image": "base64_encoded_image",
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
  "visible_features": ["door", "intercom", "numbers"],
  "points_earned": 15,
  "ai_metadata": {
    "provider": "Groq",
    "model": "meta-llama/llama-4-scout-17b-16e-instruct"
  }
}
```