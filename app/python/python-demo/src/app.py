from flask import Flask, jsonify
from iilib.factory.logger_factory import get_logger_from_env
from iilib.handler.vault_settings_handler import VaultSettingsHandler
import os
vault_handler = VaultSettingsHandler()
vault_handler.initialize_env()
logger = get_logger_from_env()
logger.add_label("application", "python_demo")
app = Flask(__name__)
@app.route('/')
def index():
    logger.info("Index route accessed.", labels={"some": "info"})
    return "Flask is running in development mode"
@app.route('/get_env')
def get_env():
    env_vars = {key: value for key, value in os.environ.items()}
    return jsonify(env_vars)
if __name__ == "__main__":
    logger.info("Starting Flask application.")
    try:
        raise ValueError("This is a test exception.")
    except Exception as e:
        logger.warning(f"An exception occurred: {e}")
app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=True)
