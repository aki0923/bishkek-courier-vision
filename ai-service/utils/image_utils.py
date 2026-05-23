import base64
import io
from PIL import Image
from config import Config
import logging

logger = logging.getLogger(__name__)


def validate_image(image: Image.Image) -> tuple[bool, str]:
    """Validate image size and format"""
    if image is None:
        return False, "Invalid image data"
    
    if image.format not in ['JPEG', 'PNG', 'WEBP']:
        return False, f"Unsupported format: {image.format}. Use JPEG, PNG, or WEBP."
    
    width, height = image.size
    if width < 200 or height < 200:
        return False, "Image too small. Minimum size: 200x200 pixels."
    
    if width > Config.GROQ_MAX_IMAGE_DIMENSION or height > Config.GROQ_MAX_IMAGE_DIMENSION:
        return False, f"Image too large. Maximum: {Config.GROQ_MAX_IMAGE_DIMENSION}px"
    
    buffer = io.BytesIO()
    image.save(buffer, format=image.format)
    size_bytes = buffer.tell()
    
    if size_bytes > Config.MAX_IMAGE_SIZE_BYTES:
        size_mb = size_bytes / (1024 * 1024)
        return False, f"Image too large: {size_mb:.1f}MB. Maximum: {Config.MAX_IMAGE_SIZE_MB}MB."
    
    return True, ""


def process_image(image: Image.Image) -> str:
    """Process and optimize image for AI analysis"""
    max_dimension = 2048
    width, height = image.size
    
    if width > max_dimension or height > max_dimension:
        logger.info(f"Resizing image from {width}x{height}")
        
        if width > height:
            new_width = max_dimension
            new_height = int(height * (max_dimension / width))
        else:
            new_height = max_dimension
            new_width = int(width * (max_dimension / height))
        
        image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG', quality=85)
    return base64.b64encode(buffer.getvalue()).decode('utf-8')