import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """AI Service Configuration with Groq"""
    
    # Groq Settings
    GROQ_API_KEY = os.getenv('GROQ_API_KEY')
    GROQ_MODEL = os.getenv('GROQ_MODEL', 'meta-llama/llama-4-scout-17b-16e-instruct')
    
    # Verification Thresholds
    MIN_CONFIDENCE_THRESHOLD = float(os.getenv('MIN_CONFIDENCE_THRESHOLD', 0.75))
    
    # Image Processing
    MAX_IMAGE_SIZE_MB = int(os.getenv('MAX_IMAGE_SIZE_MB', 10))
    MAX_IMAGE_SIZE_BYTES = MAX_IMAGE_SIZE_MB * 1024 * 1024
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}
    
    # Groq specific limits
    GROQ_IMAGE_MAX_SIZE_MB = 20  # Groq supports up to 20MB
    GROQ_MAX_IMAGE_DIMENSION = 4096  # Max width/height
    
    # Rate Limiting
    MAX_REQUESTS_PER_MINUTE = 30  # Groq free tier limit
    
    @staticmethod
    def validate_config():
        """Validate required configuration"""
        if not Config.GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY is not set in environment variables")
        
        return True