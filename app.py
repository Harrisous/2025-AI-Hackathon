"""
Backend API for Raspberry Pi Camera Data Ingestion
Receives images and audio files, stores them, and sends confirmation
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
from datetime import datetime
import logging
from pathlib import Path
import json

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'data'
IMAGES_FOLDER = os.path.join(UPLOAD_FOLDER, 'images')
AUDIO_FOLDER = os.path.join(UPLOAD_FOLDER, 'audio')
METADATA_FOLDER = os.path.join(UPLOAD_FOLDER, 'metadata')
ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}
ALLOWED_AUDIO_EXTENSIONS = {'wav', 'mp3', 'ogg', 'flac', 'm4a', 'aac'}
MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100MB max file size

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create necessary directories
for folder in [IMAGES_FOLDER, AUDIO_FOLDER, METADATA_FOLDER]:
    Path(folder).mkdir(parents=True, exist_ok=True)
    logger.info(f"Created/verified directory: {folder}")


def allowed_file(filename, allowed_extensions):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in allowed_extensions


def generate_filename(original_filename, file_type):
    """Generate unique filename with timestamp"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    extension = original_filename.rsplit('.', 1)[1].lower()
    return f"{file_type}_{timestamp}.{extension}"


def save_metadata(file_id, file_type, original_filename, saved_filename, file_size):
    """Save metadata about uploaded file"""
    metadata = {
        'file_id': file_id,
        'file_type': file_type,
        'original_filename': original_filename,
        'saved_filename': saved_filename,
        'file_size': file_size,
        'upload_timestamp': datetime.now().isoformat(),
        'status': 'received'
    }
    
    metadata_file = os.path.join(METADATA_FOLDER, f"{file_id}.json")
    with open(metadata_file, 'w') as f:
        json.dump(metadata, f, indent=2)
    
    return metadata


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'raspberry-pi-backend',
        'timestamp': datetime.now().isoformat()
    }), 200


@app.route('/upload/image', methods=['POST'])
def upload_image():
    """
    Endpoint to receive images from Raspberry Pi
    Expected: multipart/form-data with 'image' field
    """
    try:
        # Check if image is in request
        if 'image' not in request.files:
            logger.warning("No image file in request")
            return jsonify({
                'success': False,
                'error': 'No image file provided'
            }), 400
        
        file = request.files['image']
        
        # Check if filename is empty
        if file.filename == '':
            logger.warning("Empty filename received")
            return jsonify({
                'success': False,
                'error': 'No file selected'
            }), 400
        
        # Validate file extension
        if not allowed_file(file.filename, ALLOWED_IMAGE_EXTENSIONS):
            logger.warning(f"Invalid image extension: {file.filename}")
            return jsonify({
                'success': False,
                'error': f'Invalid file type. Allowed: {", ".join(ALLOWED_IMAGE_EXTENSIONS)}'
            }), 400
        
        # Generate unique filename
        original_filename = secure_filename(file.filename)
        saved_filename = generate_filename(original_filename, 'image')
        file_path = os.path.join(IMAGES_FOLDER, saved_filename)
        
        # Save file
        file.save(file_path)
        file_size = os.path.getsize(file_path)
        
        # Generate file ID
        file_id = saved_filename.rsplit('.', 1)[0]
        
        # Save metadata
        metadata = save_metadata(file_id, 'image', original_filename, saved_filename, file_size)
        
        logger.info(f"Image received and saved: {saved_filename} ({file_size} bytes)")
        
        return jsonify({
            'success': True,
            'message': 'Image received and stored successfully',
            'file_id': file_id,
            'filename': saved_filename,
            'size': file_size,
            'timestamp': metadata['upload_timestamp']
        }), 200
        
    except Exception as e:
        logger.error(f"Error uploading image: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/upload/audio', methods=['POST'])
def upload_audio():
    """
    Endpoint to receive audio from Raspberry Pi
    Expected: multipart/form-data with 'audio' field
    """
    try:
        # Check if audio is in request
        if 'audio' not in request.files:
            logger.warning("No audio file in request")
            return jsonify({
                'success': False,
                'error': 'No audio file provided'
            }), 400
        
        file = request.files['audio']
        
        # Check if filename is empty
        if file.filename == '':
            logger.warning("Empty filename received")
            return jsonify({
                'success': False,
                'error': 'No file selected'
            }), 400
        
        # Validate file extension
        if not allowed_file(file.filename, ALLOWED_AUDIO_EXTENSIONS):
            logger.warning(f"Invalid audio extension: {file.filename}")
            return jsonify({
                'success': False,
                'error': f'Invalid file type. Allowed: {", ".join(ALLOWED_AUDIO_EXTENSIONS)}'
            }), 400
        
        # Generate unique filename
        original_filename = secure_filename(file.filename)
        saved_filename = generate_filename(original_filename, 'audio')
        file_path = os.path.join(AUDIO_FOLDER, saved_filename)
        
        # Save file
        file.save(file_path)
        file_size = os.path.getsize(file_path)
        
        # Generate file ID
        file_id = saved_filename.rsplit('.', 1)[0]
        
        # Save metadata
        metadata = save_metadata(file_id, 'audio', original_filename, saved_filename, file_size)
        
        logger.info(f"Audio received and saved: {saved_filename} ({file_size} bytes)")
        
        return jsonify({
            'success': True,
            'message': 'Audio received and stored successfully',
            'file_id': file_id,
            'filename': saved_filename,
            'size': file_size,
            'timestamp': metadata['upload_timestamp']
        }), 200
        
    except Exception as e:
        logger.error(f"Error uploading audio: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/upload/batch', methods=['POST'])
def upload_batch():
    """
    Endpoint to receive both image and audio in a single request
    Expected: multipart/form-data with 'image' and 'audio' fields
    """
    try:
        results = {
            'success': True,
            'image': None,
            'audio': None,
            'errors': []
        }
        
        # Process image if present
        if 'image' in request.files:
            file = request.files['image']
            if file.filename != '' and allowed_file(file.filename, ALLOWED_IMAGE_EXTENSIONS):
                original_filename = secure_filename(file.filename)
                saved_filename = generate_filename(original_filename, 'image')
                file_path = os.path.join(IMAGES_FOLDER, saved_filename)
                file.save(file_path)
                file_size = os.path.getsize(file_path)
                file_id = saved_filename.rsplit('.', 1)[0]
                metadata = save_metadata(file_id, 'image', original_filename, saved_filename, file_size)
                
                results['image'] = {
                    'file_id': file_id,
                    'filename': saved_filename,
                    'size': file_size,
                    'timestamp': metadata['upload_timestamp']
                }
                logger.info(f"Batch: Image saved - {saved_filename}")
            else:
                results['errors'].append('Invalid or empty image file')
        
        # Process audio if present
        if 'audio' in request.files:
            file = request.files['audio']
            if file.filename != '' and allowed_file(file.filename, ALLOWED_AUDIO_EXTENSIONS):
                original_filename = secure_filename(file.filename)
                saved_filename = generate_filename(original_filename, 'audio')
                file_path = os.path.join(AUDIO_FOLDER, saved_filename)
                file.save(file_path)
                file_size = os.path.getsize(file_path)
                file_id = saved_filename.rsplit('.', 1)[0]
                metadata = save_metadata(file_id, 'audio', original_filename, saved_filename, file_size)
                
                results['audio'] = {
                    'file_id': file_id,
                    'filename': saved_filename,
                    'size': file_size,
                    'timestamp': metadata['upload_timestamp']
                }
                logger.info(f"Batch: Audio saved - {saved_filename}")
            else:
                results['errors'].append('Invalid or empty audio file')
        
        if not results['image'] and not results['audio']:
            results['success'] = False
            results['errors'].append('No valid files uploaded')
            return jsonify(results), 400
        
        return jsonify(results), 200
        
    except Exception as e:
        logger.error(f"Error in batch upload: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/files', methods=['GET'])
def list_files():
    """List all uploaded files"""
    try:
        images = os.listdir(IMAGES_FOLDER)
        audio = os.listdir(AUDIO_FOLDER)
        
        return jsonify({
            'success': True,
            'images': {
                'count': len(images),
                'files': images
            },
            'audio': {
                'count': len(audio),
                'files': audio
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error listing files: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/metadata/<file_id>', methods=['GET'])
def get_metadata(file_id):
    """Get metadata for a specific file"""
    try:
        metadata_file = os.path.join(METADATA_FOLDER, f"{file_id}.json")
        
        if not os.path.exists(metadata_file):
            return jsonify({
                'success': False,
                'error': 'Metadata not found'
            }), 404
        
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
        
        return jsonify({
            'success': True,
            'metadata': metadata
        }), 200
        
    except Exception as e:
        logger.error(f"Error retrieving metadata: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/query/images_by_time', methods=['GET'])
def query_images_by_time():
    """
    Query images by time range
    Parameters: start_time, end_time (format: YYYYMMDD_HHMMSS)
    """
    try:
        start_time = request.args.get('start_time')
        end_time = request.args.get('end_time')
        
        if not start_time or not end_time:
            return jsonify({
                'success': False,
                'error': 'start_time and end_time parameters required'
            }), 400
        
        # Parse timestamps from filenames
        images = []
        for filename in os.listdir(IMAGES_FOLDER):
            if filename.startswith('image_'):
                # Extract timestamp from filename: image_YYYYMMDD_HHMMSS_microseconds.jpg
                parts = filename.replace('.jpg', '').split('_')
                if len(parts) >= 3:
                    file_timestamp = f"{parts[1]}_{parts[2]}"
                    
                    if start_time <= file_timestamp <= end_time:
                        images.append({
                            'filename': filename,
                            'timestamp': file_timestamp,
                            'path': os.path.join(IMAGES_FOLDER, filename)
                        })
        
        images.sort(key=lambda x: x['timestamp'])
        
        return jsonify({
            'success': True,
            'count': len(images),
            'start_time': start_time,
            'end_time': end_time,
            'images': images
        }), 200
        
    except Exception as e:
        logger.error(f"Error querying images: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/query/audio_chunks', methods=['GET'])
def query_audio_chunks():
    """
    List all audio chunks with their time ranges
    """
    try:
        chunks = []
        for filename in os.listdir(AUDIO_FOLDER):
            if filename.startswith('audio_chunk_') or filename.startswith('audio_'):
                # Extract timestamp from filename
                parts = filename.replace('.wav', '').split('_')
                if len(parts) >= 3:
                    chunk_timestamp = f"{parts[-2]}_{parts[-1]}"
                    
                    chunks.append({
                        'filename': filename,
                        'chunk_id': filename.replace('.wav', ''),
                        'start_timestamp': chunk_timestamp,
                        'path': os.path.join(AUDIO_FOLDER, filename)
                    })
        
        chunks.sort(key=lambda x: x['start_timestamp'])
        
        return jsonify({
            'success': True,
            'count': len(chunks),
            'chunks': chunks
        }), 200
        
    except Exception as e:
        logger.error(f"Error querying audio chunks: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    logger.info("Starting Raspberry Pi Backend Server...")
    logger.info(f"Images will be stored in: {IMAGES_FOLDER}")
    logger.info(f"Audio will be stored in: {AUDIO_FOLDER}")
    logger.info(f"Metadata will be stored in: {METADATA_FOLDER}")
    
    # Run the app
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)
