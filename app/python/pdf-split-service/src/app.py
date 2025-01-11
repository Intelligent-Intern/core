from flask import Flask, jsonify, request
from iilib.handler.vault_settings_handler import VaultSettingsHandler
from iilib.factory.ii_factory import IIFactory
from urllib.parse import unquote
import traceback
import fitz

try:
    vault_handler = VaultSettingsHandler()
    vault_handler.initialize_env()
except Exception as e:
    print(f"Error initializing environment: {traceback.format_exc()}")
    raise

try:
    iifactory = IIFactory()
    logger = iifactory.getLogger(application="pdf_split_service")
    storage_handler = iifactory.getStorageHandler()
except Exception as e:
    print(f"Error initializing logger or storage handler: {traceback.format_exc()}")
    raise

app = Flask(__name__)

def download_pdf(bucket_name, pdf_key):
    try:
        pdf_obj = storage_handler.get_object(bucket_name, pdf_key)
        return pdf_obj['Body'].read()
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"Error fetching object from bucket {bucket_name} with key {pdf_key}: {e}\n{error_trace}")
        raise

def upload_png(bucket_name, png_key, png_data):
    try:
        storage_handler.put_object(bucket_name, png_key, png_data)
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"Error uploading PNG to bucket {bucket_name} with key {png_key}: {e}\n{error_trace}")
        raise

def process_pdf(bucket_name, file_location):
    try:
        pdf_data = download_pdf(bucket_name, file_location)
        pdf_document = fitz.open(stream=pdf_data, filetype="pdf")
        userid, uuid = file_location.split("_", 1)
        uuid = uuid.replace(".pdf", "")
        for page_num in range(len(pdf_document)):
            page = pdf_document.load_page(page_num)
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
            img_data = pix.tobytes("png")
            png_key = f"{userid}_{uuid}.{page_num + 1}.pdf.png"
            upload_png(bucket_name, png_key, img_data)
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"Error processing PDF {file_location}: {e}\n{error_trace}")
        raise

@app.route('/process_pdf', methods=['POST'])
def process_pdf_endpoint():
    try:
        received_json = request.json
        content = received_json.get('content')
        if not content:
            raise ValueError("No content provided in the request")
        raw_key = content.get('Key')
        key = unquote(raw_key)
        bucket_name = content.get('Records', [{}])[0].get('s3', {}).get('bucket', {}).get('name')
        if not key or not bucket_name:
            raise ValueError("Missing Key or Bucket name in the provided content")
        if key.startswith(f"{bucket_name}/"):
            key = key[len(f"{bucket_name}/"):]
        process_pdf(bucket_name, key)
        return jsonify({"message": "PDF processed successfully"}), 200
    except Exception as e:
        error_trace = traceback.format_exc()
        logger.error(f"Error in process_pdf_endpoint: {e}\n{error_trace}")
        return jsonify({"error": f"Failed to process PDF: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=True)