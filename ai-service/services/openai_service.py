import openai
import base64
from typing import Dict, Any, Optional
from config import Config
import logging

logger = logging.getLogger(__name__)


class OpenAIService:
    """Service for interacting with OpenAI Vision API"""
    
    def __init__(self):
        self.api_key = Config.OPENAI_API_KEY
        openai.api_key = self.api_key
    
    def encode_image_to_base64(self, image_path: str) -> str:
        """Encode image file to base64 string"""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    
    def analyze_image(
        self,
        image_data: str,
        prompt: str,
        max_tokens: int = 500
    ) -> Dict[str, Any]:
        """
        Analyze image using OpenAI Vision API
        
        Args:
            image_data: Base64 encoded image or URL
            prompt: Analysis prompt
            max_tokens: Maximum tokens in response
            
        Returns:
            Dictionary with analysis results
        """
        try:
            # Determine if image_data is URL or base64
            if image_data.startswith('http'):
                image_input = {"type": "image_url", "image_url": {"url": image_data}}
            else:
                image_input = {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{image_data}"}
                }
            
            # Call OpenAI API
            response = openai.chat.completions.create(
                model="gpt-4-vision-preview",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            image_input
                        ]
                    }
                ],
                max_tokens=max_tokens
            )
            
            # Extract response
            result = response.choices[0].message.content
            
            logger.info(f"OpenAI analysis completed successfully")
            
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
            logger.error(f"OpenAI API error: {str(e)}")
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
        prompt = """
Analyze this image and determine if it shows a building entrance, gate, doorway, or entrance to a residential complex.

Respond in JSON format with the following fields:
{
    "is_entrance": true/false,
    "confidence": 0.0-1.0,
    "entrance_type": "main_entrance|side_entrance|gate|doorway|intercom|none",
    "visible_features": ["feature1", "feature2"],
    "details": "Brief description"
}

Consider the following:
- Does it show a door, gate, or entrance?
- Are there entrance numbers, intercom buttons, or door codes visible?
- Is this a legitimate entrance photo (not a meme, random image, or spam)?
- Quality: Is the photo clear enough to be helpful?

Be strict: Only mark as entrance if it clearly shows an entry point to a building.
"""
        
        result = self.analyze_image(image_data, prompt)
        
        if not result['success']:
            return {
                'is_entrance': False,
                'confidence': 0.0,
                'error': result.get('error')
            }
        
        try:
            # Parse JSON response from OpenAI
            import json
            analysis = json.loads(result['result'])
            
            return {
                'is_entrance': analysis.get('is_entrance', False),
                'confidence': float(analysis.get('confidence', 0.0)),
                'entrance_type': analysis.get('entrance_type', 'unknown'),
                'visible_features': analysis.get('visible_features', []),
                'details': analysis.get('details', ''),
                'usage': result['usage']
            }
            
        except json.JSONDecodeError:
            # If response is not JSON, try to parse it manually
            response_text = result['result'].lower()
            
            is_entrance = any(word in response_text for word in [
                'entrance', 'door', 'gate', 'doorway', 'intercom'
            ])
            
            return {
                'is_entrance': is_entrance,
                'confidence': 0.6 if is_entrance else 0.4,
                'entrance_type': 'unknown',
                'details': result['result'],
                'usage': result['usage']
            }
    
    def detect_spam(self, image_data: str) -> Dict[str, Any]:
        """
        Detect if image is spam, meme, or inappropriate
        
        Returns:
            {
                'is_spam': bool,
                'spam_type': str,
                'confidence': float,
                'reason': str
            }
        """
        prompt = """
Analyze this image and determine if it is spam, a meme, inappropriate, or not relevant to building entrances.

Respond in JSON format:
{
    "is_spam": true/false,
    "spam_type": "meme|inappropriate|random_photo|screenshot|text_image|none",
    "confidence": 0.0-1.0,
    "reason": "Brief explanation"
}

Mark as spam if:
- It's a meme or joke image
- Contains inappropriate content
- Is a screenshot of something (not a real photo)
- Is a random photo not related to building entrances
- Contains only text (advertisement, flyer, etc.)
"""
        
        result = self.analyze_image(image_data, prompt)
        
        if not result['success']:
            return {
                'is_spam': True,  # Err on the side of caution
                'confidence': 0.5,
                'error': result.get('error')
            }
        
        try:
            import json
            analysis = json.loads(result['result'])
            
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
                'meme', 'inappropriate', 'spam', 'not relevant'
            ])
            
            return {
                'is_spam': is_spam,
                'spam_type': 'unknown',
                'confidence': 0.5,
                'reason': result['result']
            }
    
    def detect_duplicate(
        self,
        image_data: str,
        existing_images: list
    ) -> Dict[str, Any]:
        """
        Check if image is a duplicate of existing images
        
        Note: For MVP, this is a simplified version.
        Production would use perceptual hashing or image similarity models.
        """
        # For MVP, we'll use OpenAI to compare descriptions
        # In production, use image hashing (pHash, dHash) or embedding similarity
        
        prompt = f"""
Describe this image focusing on:
- Main visual elements
- Location/setting
- Distinctive features
- Lighting conditions

Keep description concise (2-3 sentences).
"""
        
        result = self.analyze_image(image_data, prompt)
        
        if not result['success']:
            return {
                'is_duplicate': False,
                'confidence': 0.0,
                'error': result.get('error')
            }
        
        # For MVP, return not duplicate
        # TODO: Implement proper duplicate detection
        return {
            'is_duplicate': False,
            'confidence': 0.0,
            'description': result['result'],
            'note': 'Duplicate detection not fully implemented in MVP'
        }