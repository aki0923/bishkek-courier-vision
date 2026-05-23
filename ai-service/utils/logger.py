"""
Logging utilities for AI service decisions
"""

import logging
import json
from datetime import datetime
from pathlib import Path


def setup_logging(log_level=logging.INFO):
    """Configure logging for the application"""
    
    log_dir = Path('logs')
    log_dir.mkdir(exist_ok=True)
    
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(log_dir / 'ai_service.log'),
        ]
    )
    
    ai_decisions_handler = logging.FileHandler(log_dir / 'ai_decisions.log')
    ai_decisions_handler.setLevel(logging.INFO)
    ai_decisions_handler.setFormatter(
        logging.Formatter('%(asctime)s - %(message)s')
    )
    
    ai_logger = logging.getLogger('ai_decisions')
    ai_logger.addHandler(ai_decisions_handler)
    ai_logger.setLevel(logging.INFO)
    
    return ai_logger


def log_ai_decision(
    operation: str,
    result: dict,
    image_hash: str = None,
    metadata: dict = None
):
    """Log AI decision for audit trail"""
    ai_logger = logging.getLogger('ai_decisions')
    
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'operation': operation,
        'provider': 'Groq',
        'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
        'result': result,
        'image_hash': image_hash,
        'metadata': metadata or {}
    }
    
    ai_logger.info(json.dumps(log_entry))


def get_ai_statistics(log_file='logs/ai_decisions.log'):
    """Parse AI decisions log and generate statistics"""
    try:
        stats = {
            'total_requests': 0,
            'entrance_verifications': 0,
            'spam_checks': 0,
            'verified_entrances': 0,
            'rejected_entrances': 0,
            'spam_detected': 0,
            'average_confidence': 0.0,
            'from_cache': 0,
            'total_tokens_used': 0
        }
        
        with open(log_file, 'r') as f:
            confidences = []
            
            for line in f:
                try:
                    json_start = line.index('{')
                    entry = json.loads(line[json_start:])
                    
                    stats['total_requests'] += 1
                    
                    operation = entry.get('operation', '')
                    result = entry.get('result', {})
                    
                    if operation == 'verify_entrance':
                        stats['entrance_verifications'] += 1
                        if result.get('is_entrance'):
                            stats['verified_entrances'] += 1
                        else:
                            stats['rejected_entrances'] += 1
                        
                        if 'confidence' in result:
                            confidences.append(result['confidence'])
                    
                    elif operation == 'detect_spam':
                        stats['spam_checks'] += 1
                        if result.get('is_spam'):
                            stats['spam_detected'] += 1
                    
                    if result.get('from_cache'):
                        stats['from_cache'] += 1
                    
                    usage = result.get('usage', {})
                    stats['total_tokens_used'] += usage.get('total_tokens', 0)
                    
                except (json.JSONDecodeError, ValueError):
                    continue
            
            if confidences:
                stats['average_confidence'] = round(sum(confidences) / len(confidences), 3)
        
        return stats
    
    except FileNotFoundError:
        return {'error': 'Log file not found'}