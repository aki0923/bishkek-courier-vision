from flask import Blueprint, request, jsonify
import base64
import io
import hashlib
from PIL import Image
import logging
from services.groq_service import GroqService
from config import Config
from utils.image_utils import validate_image, process_image
from utils.logger import log_ai_decision, get_ai_statistics

bp = Blueprint('ai', __name__, url_prefix='/ai')
logger = logging.getLogger(__name__)

groq_service = GroqService()


@bp.route('/verify-entrance', methods=['POST'])
def verify_entrance():
    """Verify entrance photo using Groq Llama 4 Scout"""
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Image data is required'
            }), 400
        
        image_data = data['image']
        address_id = data.get('address_id')
        
        image_hash = hashlib.md5(image_data.encode()).hexdigest()[:16]
        
        logger.info(f"Verifying entrance (hash: {image_hash}, address: {address_id})")
        
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
        
        # Step 1: Spam check
        logger.info("Step 1: Spam check with Llama 4 Scout...")
        spam_result = groq_service.detect_spam(image_data)
        
        log_ai_decision(
            operation='detect_spam',
            result=spam_result,
            image_hash=image_hash,
            metadata={'address_id': address_id}
        )
        
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
        
        # Step 2: Entrance verification
        logger.info("Step 2: Entrance verification with Llama 4 Scout...")
        entrance_result = groq_service.verify_entrance_photo(image_data)
        
        log_ai_decision(
            operation='verify_entrance',
            result=entrance_result,
            image_hash=image_hash,
            metadata={'address_id': address_id}
        )
        
        is_valid = (
            entrance_result['is_entrance'] and 
            entrance_result['confidence'] >= Config.MIN_CONFIDENCE_THRESHOLD
        )
        
        points_earned = 0
        if is_valid:
            points_earned = 10
            if entrance_result['confidence'] >= 0.9:
                points_earned += 5
            visible_features = entrance_result.get('visible_features', [])
            if len(visible_features) >= 3:
                points_earned += 5
        
        logger.info(f"Result: Valid={is_valid}, Points={points_earned}, Cached={entrance_result.get('from_cache', False)}")
        
        return jsonify({
            'status': 'success',
            'is_valid_entrance': is_valid,
            'confidence': entrance_result['confidence'],
            'entrance_type': entrance_result.get('entrance_type'),
            'visible_features': entrance_result.get('visible_features', []),
            'details': entrance_result.get('details'),
            'points_earned': points_earned,
            'from_cache': entrance_result.get('from_cache', False),
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
            'message': 'Internal server error'
        }), 500


@bp.route('/statistics', methods=['GET'])
def get_statistics():
    """Get AI service statistics"""
    try:
        stats = get_ai_statistics()
        
        from services.cache_service import ai_cache
        cache_stats = ai_cache.get_stats()
        
        return jsonify({
            'status': 'success',
            'ai_provider': 'Groq Llama 4 Scout',
            'ai_decisions': stats,
            'cache': cache_stats
        })
        
    except Exception as e:
        logger.error(f"Statistics error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
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
    
@bp.route('/verify-batch', methods=['POST'])
def verify_batch():
    """
    Verify multiple images in batch using Groq Llama 4 Scout
    
    Request:
    {
        "images": [
            {"id": "1", "image": "base64_data", "address_id": 1},
            {"id": "2", "image": "base64_data", "address_id": 2}
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'images' not in data:
            return jsonify({
                'status': 'error',
                'message': 'Images array is required'
            }), 400
        
        images = data['images']
        
        if not isinstance(images, list) or len(images) == 0:
            return jsonify({
                'status': 'error',
                'message': 'Images must be a non-empty array'
            }), 400
        
        if len(images) > 10:
            return jsonify({
                'status': 'error',
                'message': 'Maximum 10 images per batch (Groq rate limit)'
            }), 400
        
        results = []
        
        for item in images:
            image_id = item.get('id')
            image_data = item.get('image')
            address_id = item.get('address_id')
            
            if not image_data:
                results.append({
                    'id': image_id,
                    'status': 'error',
                    'message': 'Missing image data'
                })
                continue
            
            try:
                # Check spam
                spam_result = groq_service.detect_spam(image_data)
                
                if spam_result['is_spam'] and spam_result['confidence'] > 0.7:
                    results.append({
                        'id': image_id,
                        'status': 'rejected',
                        'reason': 'spam',
                        'details': spam_result['reason']
                    })
                    continue
                
                # Verify entrance
                entrance_result = groq_service.verify_entrance_photo(image_data)
                
                is_valid = (
                    entrance_result['is_entrance'] and 
                    entrance_result['confidence'] >= Config.MIN_CONFIDENCE_THRESHOLD
                )
                
                points_earned = 0
                if is_valid:
                    points_earned = 10
                    if entrance_result['confidence'] >= 0.9:
                        points_earned += 5
                
                results.append({
                    'id': image_id,
                    'status': 'success' if is_valid else 'rejected',
                    'is_valid_entrance': is_valid,
                    'confidence': entrance_result['confidence'],
                    'points_earned': points_earned,
                    'from_cache': entrance_result.get('from_cache', False)
                })
                
            except Exception as e:
                logger.error(f"Error processing image {image_id}: {e}")
                results.append({
                    'id': image_id,
                    'status': 'error',
                    'message': str(e)
                })
        
        return jsonify({
            'status': 'success',
            'results': results,
            'total_processed': len(results),
            'ai_provider': 'Groq Llama 4 Scout'
        })
        
    except Exception as e:
        logger.error(f"Batch verification error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': 'Internal server error'
        }), 500