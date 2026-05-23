from flask import Blueprint, request, jsonify
import base64
import io
from PIL import Image
import logging
from services.groq_service import GroqService
from config import Config
from utils.image_utils import validate_image, process_image

bp = Blueprint('ai', __name__, url_prefix='/ai')
logger = logging.getLogger(__name__)

# Initialize Groq service
groq_service = GroqService()


@bp.route('/verify-entrance', methods=['POST'])
def verify_entrance():
    """
    Verify if uploaded image shows a building entrance
    Uses Groq's Llama 4 Scout model (free, fast)
    """
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Image data is required'
            }), 400
        
        image_data = data['image']
        address_id = data.get('address_id')
        
        logger.info(f"Verifying entrance photo for address_id: {address_id}")
        
        # Validate image (if base64)
        if not image_data.startswith('http'):
            try:
                image_bytes = base64.b64decode(image_data)
                image = Image.open(io.BytesIO(image_bytes))
                
                is_valid, error_message = validate_image(image)
                if not is_valid:
                    return jsonify({
                        'status': 'error',
                        'message': error_message
                    }), 400
                
                image_data = process_image(image)
                
            except Exception as e:
                logger.error(f"Image validation error: {str(e)}")
                return jsonify({
                    'status': 'error',
                    'message': 'Invalid image format'
                }), 400
        
        # Step 1: Check for spam
        logger.info("Step 1: Checking for spam with Llama 4 Scout...")
        spam_result = groq_service.detect_spam(image_data)
        
        if spam_result['is_spam'] and spam_result['confidence'] > 0.7:
            logger.warning(f"Spam detected: {spam_result['spam_type']}")
            return jsonify({
                'status': 'rejected',
                'reason': 'spam',
                'is_valid_entrance': False,
                'confidence': spam_result['confidence'],
                'details': spam_result['reason'],
                'points_earned': 0,
                'ai_provider': 'Groq Llama 4 Scout'
            })
        
        # Step 2: Verify entrance
        logger.info("Step 2: Verifying entrance with Llama 4 Scout...")
        entrance_result = groq_service.verify_entrance_photo(image_data)
        
        # Determine if entrance is valid
        is_valid = (
            entrance_result['is_entrance'] and 
            entrance_result['confidence'] >= Config.MIN_CONFIDENCE_THRESHOLD
        )
        
        # Calculate points
        points_earned = 0
        if is_valid:
            points_earned = 10
            
            if entrance_result['confidence'] >= 0.9:
                points_earned += 5
            
            visible_features = entrance_result.get('visible_features', [])
            if len(visible_features) >= 3:
                points_earned += 5
        
        logger.info(f"Verification complete. Valid: {is_valid}, Points: {points_earned}")
        
        return jsonify({
            'status': 'success',
            'is_valid_entrance': is_valid,
            'confidence': entrance_result['confidence'],
            'entrance_type': entrance_result.get('entrance_type'),
            'visible_features': entrance_result.get('visible_features', []),
            'details': entrance_result.get('details'),
            'points_earned': points_earned,
            'ai_metadata': {
                'provider': 'Groq',
                'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
                'tokens_used': entrance_result.get('usage', {}).get('total_tokens', 0)
            }
        })
        
    except Exception as e:
        logger.error(f"Entrance verification error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': 'Internal server error during verification'
        }), 500


@bp.route('/check-spam', methods=['POST'])
def check_spam():
    """Check if image is spam"""
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Image data is required'
            }), 400
        
        image_data = data['image']
        result = groq_service.detect_spam(image_data)
        
        return jsonify({
            'status': 'success',
            'is_spam': result['is_spam'],
            'spam_type': result.get('spam_type'),
            'confidence': result['confidence'],
            'reason': result.get('reason'),
            'ai_provider': 'Groq Llama 4 Scout'
        })
        
    except Exception as e:
        logger.error(f"Spam check error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


@bp.route('/detect-duplicate', methods=['POST'])
def detect_duplicate():
    """Check for duplicate images"""
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Image data is required'
            }), 400
        
        image_data = data['image']
        address_id = data.get('address_id')
        
        existing_images = []  # TODO: Fetch from database
        
        result = groq_service.detect_duplicate(image_data, existing_images)
        
        return jsonify({
            'status': 'success',
            'is_duplicate': result['is_duplicate'],
            'confidence': result['confidence'],
            'note': result.get('note')
        })
        
    except Exception as e:
        logger.error(f"Duplicate detection error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500