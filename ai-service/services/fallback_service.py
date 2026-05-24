"""
Fallback mechanisms when Groq API is unavailable
Provides graceful degradation
"""

import logging
from typing import Dict, Any
from PIL import Image
import base64
import io

logger = logging.getLogger(__name__)


class FallbackService:
    """Provides fallback responses when AI is unavailable"""
    
    @staticmethod
    def basic_image_check(image_data: str) -> Dict[str, Any]:
        """
        Basic image validation without AI
        Used as fallback when Groq is down
        """
        try:
            # Decode image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            
            # Basic checks
            width, height = image.size
            
            # Check if image has reasonable dimensions for a photo
            is_likely_photo = (
                width >= 400 and 
                height >= 400 and 
                width / height < 4 and 
                height / width < 4
            )
            
            return {
                'is_entrance': is_likely_photo,
                'confidence': 0.5 if is_likely_photo else 0.3,
                'entrance_type': 'unknown',
                'visible_features': [],
                'details': 'AI service unavailable - basic validation only',
                'fallback': True,
                'requires_manual_review': True
            }
            
        except Exception as e:
            logger.error(f"Fallback check error: {e}")
            return {
                'is_entrance': False,
                'confidence': 0.0,
                'error': str(e),
                'fallback': True
            }
    
    @staticmethod
    def basic_spam_check(image_data: str) -> Dict[str, Any]:
        """Basic spam check without AI"""
        try:
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            
            # Very basic heuristic - just check if it's a real image
            width, height = image.size
            
            # Assume not spam if dimensions are reasonable
            is_spam = width < 200 or height < 200
            
            return {
                'is_spam': is_spam,
                'spam_type': 'unknown',
                'confidence': 0.5,
                'reason': 'Fallback validation - manual review needed',
                'fallback': True
            }
            
        except Exception as e:
            return {
                'is_spam': True,  # Err on safe side
                'confidence': 0.5,
                'error': str(e),
                'fallback': True
            }