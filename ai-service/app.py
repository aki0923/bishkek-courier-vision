from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import routes
from routes import ai_routes

# Register blueprints
app.register_blueprint(ai_routes.bp)


@app.route('/')
def index():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Bishkek Courier Vision AI Service',
        'version': '1.0.0',
        'ai_provider': 'Groq',
        'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
        'endpoints': {
            'POST /ai/verify-entrance': 'Verify if image shows a building entrance',
            'POST /ai/detect-duplicate': 'Check for duplicate images',
            'POST /ai/check-spam': 'Filter spam/inappropriate images',
            'GET /ai/health': 'Service health check'
        }
    })


@app.route('/ai/health')
def health():
    """Detailed health check"""
    groq_key_configured = bool(os.getenv('GROQ_API_KEY'))
    
    return jsonify({
        'status': 'healthy',
        'groq_configured': groq_key_configured,
        'model': os.getenv('GROQ_MODEL', 'meta-llama/llama-4-scout-17b-16e-instruct'),
        'environment': os.getenv('FLASK_ENV', 'production')
    })


@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f'Internal server error: {error}')
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)