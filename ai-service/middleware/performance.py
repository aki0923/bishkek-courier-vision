"""Performance monitoring for Groq API calls"""

import time
import logging
from functools import wraps
from flask import request, g

logger = logging.getLogger(__name__)


def track_performance(f):
    """Decorator to track endpoint performance"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        g.start_time = time.time()
        result = f(*args, **kwargs)
        duration = time.time() - g.start_time
        
        logger.info(
            f"Performance: {request.method} {request.path} "
            f"completed in {duration:.3f}s"
        )
        
        if duration > 10:  # Groq is fast, anything >10s is concerning
            logger.warning(
                f"SLOW REQUEST: {request.method} {request.path} "
                f"took {duration:.3f}s"
            )
        
        return result
    
    return decorated_function


def init_performance_monitoring(app):
    """Initialize performance monitoring"""
    
    @app.before_request
    def before_request():
        g.start_time = time.time()
    
    @app.after_request
    def after_request(response):
        if hasattr(g, 'start_time'):
            duration = time.time() - g.start_time
            response.headers['X-Response-Time'] = f"{duration:.3f}s"
            response.headers['X-AI-Provider'] = 'Groq-Llama4-Scout'
            
            if duration > 5:
                logger.warning(
                    f"Slow request: {request.method} {request.path} "
                    f"took {duration:.3f}s"
                )
        
        return response