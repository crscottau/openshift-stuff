#!/usr/bin/env python3
"""
API Proxy Server

A simple HTTP proxy server that forwards API requests to target endpoints.
Useful for adding CORS headers, logging, authentication, or other middleware functionality.
"""

from flask import Flask, request, Response
import requests
import json
import logging
from urllib.parse import urljoin
import argparse
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
#global TARGET_API_BASE_URL

def forward_request(target_url, method, headers, data=None, params=None):
    """Forward the request to the target API and return the response."""
    try:
        # Remove host header to avoid conflicts
        headers_to_forward = {k: v for k, v in headers.items() 
                            if k.lower() not in ['host', 'content-length']}
        
        # Make the request to the target API
        response = requests.request(
            method=method,
            url=target_url,
            headers=headers_to_forward,
            data=data,
            params=params,
            timeout=30,
            stream=True
        )
        
        # Log the request
        logger.info(f"{method} {target_url} -> {response.status_code}")
        
        return response
    
    except requests.exceptions.RequestException as e:
        logger.error(f"Error forwarding request: {e}")
        return None

@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
def proxy(path):
    """Main proxy endpoint that handles all requests."""
    
    # Construct the target URL
    target_url = urljoin(target_api_base_url.rstrip('/') + '/', path)
    if request.query_string:
        target_url += '?' + request.query_string.decode('utf-8')
    
    # Get request data
    data = request.get_data()
    headers = dict(request.headers)
    
    # Forward the request
    response = forward_request(
        target_url=target_url,
        method=request.method,
        headers=headers,
        data=data if data else None,
        params=None  # Already included in target_url
    )
    
    if response is None:
        return Response(
            json.dumps({"error": "Failed to connect to target API"}),
            status=502,
            mimetype='application/json'
        )
    
    # Create response with same content and headers
    excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
    headers_to_return = [(name, value) for (name, value) in response.headers.items()
                        if name.lower() not in excluded_headers]
    
    # Add CORS headers
    headers_to_return.extend([
        ('Access-Control-Allow-Origin', '*'),
        ('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS'),
        ('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'),
    ])
    
    # Handle OPTIONS requests (CORS preflight)
    if request.method == 'OPTIONS':
        return Response('', status=200, headers=headers_to_return)
    
    return Response(
        response.content,
        status=response.status_code,
        headers=headers_to_return
    )

@app.route('/health')
def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "proxy_target": target_api_base_url}

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return {"error": "Endpoint not found"}, 404

@app.errorhandler(500)
def internal_error(error):
    """Handle internal server errors."""
    logger.error(f"Internal server error: {error}")
    return {"error": "Internal server error"}, 500

def main():

    global target_api_base_url
    #TARGET_API_BASE_URL = "htTARGET_API_BASE_URLtps://api.openshift.com"
    #PROXY_PORT = 8080

    """Read environment variables"""
    #parser = argparse.ArgumentParser(description='API Proxy Server')
    #parser.add_argument('--target', '-t', 
    #                   default=TARGET_API_BASE_URL,
    #                   help='Target API base URL')
    #parser.add_argument('--port', '-p', 
    #                   type=int, default=PROXY_PORT,
    #                   help='Port to run the proxy server on')
    #parser.add_argument('--host', 
    #                   default='localhost',
    #                   help='Host to bind the server to')
    #parser.add_argument('--debug', 
    #                   action='store_true',
    #                   help='Run in debug mode')

    proxy_host = os.environ.get('PROXY_HOST', 'localhost')
    proxy_port = os.environ.get('PROXY_PORT', '8080')
    target_api_base_url = os.environ.get('TARGET_API_BASE_URL', 'https://api.openshift.com')
    #port = os.environ.get('PROXY_PORT', '8080')

    #args = parser.parse_args()
    #
    #TARGET_API_BASE_URL = args.target
    
    logger.info(f"Starting API proxy server on {proxy_host}:{proxy_port}")
    logger.info(f"Proxying requests to: {target_api_base_url}")

    """Main function to run the proxy server."""   
    app.run(
        host=proxy_host,
        port=proxy_port,
        threaded=True
    )

if __name__ == '__main__':
    main()
