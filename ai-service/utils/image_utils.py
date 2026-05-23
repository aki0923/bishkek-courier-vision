import base64
import io
from PIL import Image, ImageOps, ImageEnhance
from config import Config
import logging

logger = logging.getLogger(__name__)


def validate_image(image: Image.Image) -> tuple[bool, str]:
    """Comprehensive image validation"""
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
    
    # Check aspect ratio
    aspect_ratio = width / height
    if aspect_ratio > 4 or aspect_ratio < 0.25:
        return False, "Image aspect ratio too extreme."
    
    return True, ""


def process_image(image: Image.Image) -> str:
    """Process and optimize image for Groq AI analysis"""
    
    # Resize if too large
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
    
    # Handle different color modes
    if image.mode not in ('RGB', 'L'):
        logger.info(f"Converting image from {image.mode} to RGB")
        if image.mode == 'RGBA':
            background = Image.new('RGB', image.size, (255, 255, 255))
            background.paste(image, mask=image.split()[3])
            image = background
        else:
            image = image.convert('RGB')
    
    # Auto-rotate based on EXIF
    try:
        image = ImageOps.exif_transpose(image)
        logger.info("Applied EXIF rotation")
    except Exception as e:
        logger.warning(f"Could not apply EXIF rotation: {e}")
    
    # Enhance image slightly
    try:
        enhancer = ImageEnhance.Sharpness(image)
        image = enhancer.enhance(1.2)
    except Exception as e:
        logger.warning(f"Could not enhance image: {e}")
    
    # Encode to base64
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG', quality=85, optimize=True)
    return base64.b64encode(buffer.getvalue()).decode('utf-8')


def extract_image_metadata(image: Image.Image) -> dict:
    """Extract metadata from image"""
    metadata = {
        'format': image.format,
        'mode': image.mode,
        'size': image.size,
        'width': image.width,
        'height': image.height,
    }
    
    try:
        exif = image._getexif()
        if exif:
            from PIL.ExifTags import TAGS
            metadata['exif'] = {}
            for tag_id, value in exif.items():
                tag = TAGS.get(tag_id, tag_id)
                metadata['exif'][str(tag)] = str(value)[:100]  # Limit length
    except Exception:
        pass
    
    return metadata


def detect_image_quality(image: Image.Image) -> dict:
    """Analyze image quality metrics"""
    quality_info = {
        'is_blurry': False,
        'is_too_dark': False,
        'is_too_bright': False,
        'quality_score': 1.0
    }
    
    try:
        # Convert to grayscale for analysis
        gray = image.convert('L')
        
        # Get pixel data
        pixels = list(gray.getdata())
        
        # Brightness analysis
        avg_brightness = sum(pixels) / len(pixels)
        
        if avg_brightness < 40:
            quality_info['is_too_dark'] = True
            quality_info['quality_score'] *= 0.7
        elif avg_brightness > 220:
            quality_info['is_too_bright'] = True
            quality_info['quality_score'] *= 0.7
        
        quality_info['average_brightness'] = round(avg_brightness, 2)
        
    except Exception as e:
        logger.warning(f"Quality detection error: {e}")
    
    return quality_info