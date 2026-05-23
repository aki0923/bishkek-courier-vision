"""
Simple caching service to reduce redundant Groq API calls
Caching makes responses instant
"""

import hashlib
import json
import time
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)


class CacheService:
    """In-memory cache for AI responses"""
    
    def __init__(self, ttl_seconds: int = 3600):
        self.cache: Dict[str, Dict[str, Any]] = {}
        self.ttl = ttl_seconds
        self.hits = 0
        self.misses = 0
    
    def _generate_key(self, image_data: str, operation: str) -> str:
        """Generate cache key from image data and operation type"""
        data_sample = image_data[:1000] if len(image_data) > 1000 else image_data
        content = f"{operation}:{data_sample}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def get(self, image_data: str, operation: str) -> Optional[Dict[str, Any]]:
        """Retrieve cached result if available and not expired"""
        key = self._generate_key(image_data, operation)
        
        if key in self.cache:
            cached_item = self.cache[key]
            age = time.time() - cached_item['timestamp']
            
            if age < self.ttl:
                self.hits += 1
                logger.info(f"Cache HIT for {operation} (age: {age:.1f}s)")
                return cached_item['result']
            else:
                logger.info(f"Cache EXPIRED for {operation}")
                del self.cache[key]
        
        self.misses += 1
        logger.info(f"Cache MISS for {operation}")
        return None
    
    def set(self, image_data: str, operation: str, result: Dict[str, Any]):
        """Store result in cache"""
        key = self._generate_key(image_data, operation)
        
        self.cache[key] = {
            'result': result,
            'timestamp': time.time()
        }
        
        logger.info(f"Cached result for {operation}")
    
    def clear(self):
        """Clear all cached items"""
        self.cache.clear()
        self.hits = 0
        self.misses = 0
        logger.info("Cache cleared")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total = self.hits + self.misses
        hit_rate = (self.hits / total * 100) if total > 0 else 0
        
        return {
            'total_items': len(self.cache),
            'hits': self.hits,
            'misses': self.misses,
            'hit_rate_percent': round(hit_rate, 2),
            'memory_usage_mb': self._estimate_memory_usage()
        }
    
    def _estimate_memory_usage(self) -> float:
        """Rough estimate of cache memory usage in MB"""
        try:
            size_bytes = len(json.dumps(self.cache))
            return round(size_bytes / (1024 * 1024), 3)
        except:
            return 0.0


# Global cache instance (1 hour TTL)
ai_cache = CacheService(ttl_seconds=3600)