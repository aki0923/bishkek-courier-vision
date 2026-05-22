import base64
import io
from PIL import Image
from config import Config
import logging

logger = logging.getLogger(__name__)


def validate_image(image: Image.Image) -> tuple[bool, str]:
    """
    Validate image size and format
    
    Returns:
        (is_valid, error_message)
    """
    # Check format
    if image.format not in ['JPEG', 'PNG', 'WEBP']:
        return False, f"Unsupported format: {image.format}. Use JPEG, PNG, or WEBP."
    
    # Check size
    width, height = image.size
    if width < 200 or height < 200:
        return False, "Image too small. Minimum size: 200x200 pixels."
    
    if width > 4096 or height > 4096:
        return False, "Image too large. Maximum size: 4096x4096 pixels."
    
    # Check file size (approximate)
    buffer = io.BytesIO()
    image.save(buffer, format=image.format)
    size_bytes = buffer.tell()
    
    if size_bytes > Config.MAX_IMAGE_SIZE_BYTES:
        size_mb = size_bytes / (1024 * 1024)
        return False, f"Image too large: {size_mb:.1f}MB. Maximum: {Config.MAX_IMAGE_SIZE_MB}MB."
    
    return True, ""


def process_image(image: Image.Image) -> str:
    """
    Process and optimize image for AI analysis
    
    Returns:
        Base64 encoded image
    """
    # Resize if too large (save API costs)
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
        logger.info(f"Resized to {new_width}x{new_height}")
    
    # Convert to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Encode to base64
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG', quality=85)
    image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
    
    return image_base64


def extract_image_metadata(image: Image.Image) -> dict:
    """Extract useful metadata from image"""
    return {
        'format': image.format,
        'mode': image.mode,
        'size': image.size,
        'width': image.width,
        'height': image.height,
    }