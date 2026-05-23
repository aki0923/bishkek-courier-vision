from groq import Groq
import base64
from typing import Dict, Any, Optional
from config import Config
import logging
import json

logger = logging.getLogger(__name__)


class GroqService:
    """Service for interacting with Groq Vision API"""
    
    def __init__(self):
        self.api_key = Config.GROQ_API_KEY
        self.model = Config.GROQ_MODEL
        
        if not self.api_key:
            raise ValueError("GROQ_API_KEY not configured")
        
        self.client = Groq(api_key=self.api_key)
        logger.info(f"Initialized Groq client with model: {self.model}")
    
    def encode_image_to_base64(self, image_path: str) -> str:
        """Encode image file to base64 string"""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    
    def analyze_image(
        self,
        image_data: str,
        prompt: str,
        max_tokens: int = 500,
        temperature: float = 0.3
    ) -> Dict[str, Any]:
        """
        Analyze image using Groq's Llama 4 Scout model
        
        Args:
            image_data: Base64 encoded image or URL
            prompt: Analysis prompt
            max_tokens: Maximum tokens in response
            temperature: Sampling temperature (lower = more consistent)
            
        Returns:
            Dictionary with analysis results
        """
        try:
            # Prepare image input - Groq supports both URL and base64
            if image_data.startswith('http'):
                image_url = image_data
            else:
                # Convert base64 to data URL
                image_url = f"data:image/jpeg;base64,{image_data}"
            
            # Call Groq API (OpenAI-compatible format)
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": prompt
                            },
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": image_url
                                }
                            }
                        ]
                    }
                ],
                max_tokens=max_tokens,
                temperature=temperature
            )
            
            # Extract response
            result = response.choices[0].message.content
            
            logger.info(f"Groq analysis completed successfully")
            
            return {
                'success': True,
                'result': result,
                'model': response.model,
                'usage': {
                    'prompt_tokens': response.usage.prompt_tokens,
                    'completion_tokens': response.usage.completion_tokens,
                    'total_tokens': response.usage.total_tokens
                }
            }
            
        except Exception as e:
            logger.error(f"Groq API error: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def verify_entrance_photo(self, image_data: str) -> Dict[str, Any]:
        """
        Verify if image shows a building entrance, gate, or doorway
        
        Returns:
            {
                'is_entrance': bool,
                'confidence': float (0-1),
                'entrance_type': str,
                'details': str
            }
        """
        prompt = """You are an expert at identifying building entrances from photos.

Analyze this image and determine if it shows a building entrance, gate, doorway, or entrance to a residential complex.

IMPORTANT: Respond with ONLY valid JSON, no other text, no markdown formatting:

{
    "is_entrance": true or false,
    "confidence": 0.0 to 1.0,
    "entrance_type": "main_entrance" or "side_entrance" or "gate" or "doorway" or "intercom" or "none",
    "visible_features": ["feature1", "feature2"],
    "details": "Brief description in one sentence"
}

Rules:
- is_entrance = true ONLY if image clearly shows a door, gate, or building entry
- confidence: 0.9+ for clear photos, 0.7-0.9 for partial views, below 0.7 for unclear
- visible_features: list what you actually see (door, intercom, numbers, handle, gate, etc)
- Be strict: memes, random photos, screenshots should be marked as false

Examples of valid entrances:
- Door with handle/knob clearly visible
- Gate with intercom button
- Building entrance with numbers
- Doorway with hallway visible

Examples of NOT entrances:
- Random photos of people, food, nature
- Memes or screenshots
- Blurry/unclear images
- Photos of walls without doors

Respond with JSON only."""
        
        result = self.analyze_image(image_data, prompt, max_tokens=300)
        
        if not result['success']:
            return {
                'is_entrance': False,
                'confidence': 0.0,
                'error': result.get('error')
            }
        
        try:
            # Parse JSON response
            response_text = result['result'].strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis = json.loads(response_text)
            
            return {
                'is_entrance': analysis.get('is_entrance', False),
                'confidence': float(analysis.get('confidence', 0.0)),
                'entrance_type': analysis.get('entrance_type', 'unknown'),
                'visible_features': analysis.get('visible_features', []),
                'details': analysis.get('details', ''),
                'usage': result['usage']
            }
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Groq response as JSON: {e}")
            logger.error(f"Raw response: {result['result']}")
            
            # Fallback parsing
            response_text = result['result'].lower()
            
            is_entrance = any(word in response_text for word in [
                'entrance', 'door', 'gate', 'doorway', 'intercom', 'building entry'
            ])
            
            return {
                'is_entrance': is_entrance,
                'confidence': 0.6 if is_entrance else 0.4,
                'entrance_type': 'unknown',
                'details': result['result'][:200],
                'usage': result['usage'],
                'parse_error': True
            }
    
    def detect_spam(self, image_data: str) -> Dict[str, Any]:
        """
        Detect if image is spam, meme, or inappropriate
        """
        prompt = """You are a content moderator. Analyze if this image is spam, meme, inappropriate, or irrelevant to building entrances.

Respond with ONLY valid JSON, no markdown:

{
    "is_spam": true or false,
    "spam_type": "meme" or "inappropriate" or "random_photo" or "screenshot" or "text_image" or "advertisement" or "none",
    "confidence": 0.0 to 1.0,
    "reason": "Brief explanation in one sentence"
}

Mark as spam if image is:
- A meme or joke image
- Contains inappropriate content
- A screenshot of phone/computer/app
- Random photo (food, selfie, nature, cars - unless entrance visible)
- Text-only image, advertisement, or flyer
- Celebrity photo or stock image

Mark as NOT spam if:
- Real photo of a building entrance
- Photo of door, gate, intercom
- Building exterior with visible entrance
- Photo taken on-site by courier

Respond with JSON only, no other text."""
        
        result = self.analyze_image(image_data, prompt, max_tokens=200)
        
        if not result['success']:
            return {
                'is_spam': True,  # Err on safe side
                'confidence': 0.5,
                'error': result.get('error')
            }
        
        try:
            response_text = result['result'].strip()
            
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis = json.loads(response_text)
            
            return {
                'is_spam': analysis.get('is_spam', False),
                'spam_type': analysis.get('spam_type', 'none'),
                'confidence': float(analysis.get('confidence', 0.0)),
                'reason': analysis.get('reason', ''),
                'usage': result['usage']
            }
            
        except json.JSONDecodeError:
            response_text = result['result'].lower()
            is_spam = any(word in response_text for word in [
                'meme', 'inappropriate', 'spam', 'not relevant', 'screenshot'
            ])
            
            return {
                'is_spam': is_spam,
                'spam_type': 'unknown',
                'confidence': 0.5,
                'reason': result['result'][:200]
            }
    
    def detect_duplicate(
        self,
        image_data: str,
        existing_images: list
    ) -> Dict[str, Any]:
        """
        Check if image is a duplicate (basic MVP implementation)
        """
        # For MVP, use description-based comparison
        prompt = """Describe this image in detail focusing on:
- Main visual elements (doors, gates, buildings)
- Distinctive features (colors, signs, numbers)
- Lighting conditions and time of day
- Surroundings

Provide a concise description in 2-3 sentences."""
        
        result = self.analyze_image(image_data, prompt, max_tokens=200)
        
        if not result['success']:
            return {
                'is_duplicate': False,
                'confidence': 0.0,
                'error': result.get('error')
            }
        
        # For MVP, return not duplicate
        return {
            'is_duplicate': False,
            'confidence': 0.0,
            'description': result['result'],
            'note': 'Full duplicate detection not implemented in MVP'
        }