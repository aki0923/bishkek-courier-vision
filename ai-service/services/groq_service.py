from groq import Groq
import base64
from typing import Dict, Any, Optional
from config import Config
import logging
import json
from services.cache_service import ai_cache
from prompts.entrance_verification import (
    get_entrance_verification_prompt,
    get_spam_detection_prompt
)
from services.fallback_service import FallbackService

logger = logging.getLogger(__name__)


class GroqService:
    """Service for Groq Vision API with caching"""
    
    def __init__(self):
        self.api_key = Config.GROQ_API_KEY
        self.model = Config.GROQ_MODEL
        
        if not self.api_key:
            raise ValueError("GROQ_API_KEY not configured")
        
        self.client = Groq(api_key=self.api_key)
        logger.info(f"Initialized Groq client with model: {self.model}")
    
    def verify_entrance_photo(self, image_data: str) -> Dict[str, Any]:
        """Verify entrance photo with fallback support"""
        
        # Check cache first
        cached_result = ai_cache.get(image_data, 'verify_entrance')
        if cached_result:
            cached_result['from_cache'] = True
            return cached_result
        
        try:
            prompt = get_entrance_verification_prompt()
            result = self.analyze_image(image_data, prompt, max_tokens=400)
            
            if not result['success']:
                # Groq failed - use fallback
                logger.warning("Groq API failed, using fallback")
                return FallbackService.basic_image_check(image_data)
        
            response_text = result['result'].strip()
            
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis = json.loads(response_text)
            
            final_result = {
                'is_entrance': analysis.get('is_entrance', False),
                'confidence': float(analysis.get('confidence', 0.0)),
                'entrance_type': analysis.get('entrance_type', 'unknown'),
                'visible_features': analysis.get('visible_features', []),
                'details': analysis.get('details', ''),
                'usage': result['usage'],
                'from_cache': False
            }
            
            # Cache the result
            ai_cache.set(image_data, 'verify_entrance', final_result)
            
            return final_result
            
        except Exception as e:
                logger.error(f"Verification failed: {e}")
                return FallbackService.basic_image_check(image_data)
    
    def detect_spam(self, image_data: str) -> Dict[str, Any]:
        """Detect spam with caching"""
        
        cached_result = ai_cache.get(image_data, 'detect_spam')
        if cached_result:
            cached_result['from_cache'] = True
            return cached_result
        
        prompt = get_spam_detection_prompt()
        
        result = self.analyze_image(image_data, prompt, max_tokens=200)
        
        if not result['success']:
            return {
                'is_spam': True,
                'confidence': 0.5,
                'error': result.get('error'),
                'from_cache': False
            }
        
        try:
            response_text = result['result'].strip()
            
            if response_text.startswith('```'):
                response_text = response_text.split('```')[1]
                if response_text.startswith('json'):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis = json.loads(response_text)
            
            final_result = {
                'is_spam': analysis.get('is_spam', False),
                'spam_type': analysis.get('spam_type', 'none'),
                'confidence': float(analysis.get('confidence', 0.0)),
                'reason': analysis.get('reason', ''),
                'usage': result['usage'],
                'from_cache': False
            }
            
            ai_cache.set(image_data, 'detect_spam', final_result)
            return final_result
            
        except json.JSONDecodeError:
            response_text = result['result'].lower()
            is_spam = any(word in response_text for word in [
                'meme', 'inappropriate', 'spam', 'screenshot'
            ])
            
            fallback_result = {
                'is_spam': is_spam,
                'spam_type': 'unknown',
                'confidence': 0.5,
                'reason': result['result'][:200],
                'from_cache': False
            }
            
            ai_cache.set(image_data, 'detect_spam', fallback_result)
            return fallback_result
    
    def analyze_image(
        self,
        image_data: str,
        prompt: str,
        max_tokens: int = 500,
        temperature: float = 0.3
    ) -> Dict[str, Any]:
        """Analyze image using Groq Llama 4 Scout"""
        try:
            if image_data.startswith('http'):
                image_url = image_data
            else:
                image_url = f"data:image/jpeg;base64,{image_data}"
            
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {"url": image_url}
                            }
                        ]
                    }
                ],
                max_tokens=max_tokens,
                temperature=temperature
            )
            
            result = response.choices[0].message.content
            logger.info("Groq analysis completed successfully")
            
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