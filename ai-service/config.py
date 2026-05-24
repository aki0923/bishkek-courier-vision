import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """AI Service Configuration with Groq"""
    
    # Groq Settings
    GROQ_API_KEY = os.getenv('GROQ_API_KEY')
    GROQ_MODEL = os.getenv('GROQ_MODEL', 'meta-llama/llama-4-scout-17b-16e-instruct')
    
    # Confidence Thresholds (tuned after testing)
    MIN_CONFIDENCE_THRESHOLD = float(os.getenv('MIN_CONFIDENCE_THRESHOLD', 0.70))
    HIGH_CONFIDENCE_THRESHOLD = 0.85
    SPAM_CONFIDENCE_THRESHOLD = 0.70
    
    # Points System (tuned)
    BASE_POINTS = {
        'photo': 10,
        'hint': 5,
        'code': 15
    }
    
    CONFIDENCE_BONUS = {
        'high': 5,      # confidence >= 0.90
        'features': 5,  # 3+ visible features
    }
    
    # Image Processing
    MAX_IMAGE_SIZE_MB = int(os.getenv('MAX_IMAGE_SIZE_MB', 10))
    MAX_IMAGE_SIZE_BYTES = MAX_IMAGE_SIZE_MB * 1024 * 1024
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}
    
    # Groq specific limits
    GROQ_IMAGE_MAX_SIZE_MB = 20
    GROQ_MAX_IMAGE_DIMENSION = 4096
    GROQ_RECOMMENDED_DIMENSION = 2048
    
    # Rate Limiting (Groq free tier: ~30 req/min)
    MAX_REQUESTS_PER_MINUTE = 25
    
    # Caching
    CACHE_TTL_SECONDS = 3600  # 1 hour
    
    @staticmethod
    def validate_config():
        """Validate required configuration"""
        if not Config.GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY is not set")
        return True
    
    @staticmethod
    def calculate_points(confidence: float, visible_features_count: int) -> int:
        """Calculate points based on AI verification result"""
        points = Config.BASE_POINTS['photo']
        
        # Bonus for high confidence
        if confidence >= 0.90:
            points += Config.CONFIDENCE_BONUS['high']
        
        # Bonus for detailed features
        if visible_features_count >= 3:
            points += Config.CONFIDENCE_BONUS['features']
        
        return points