from flask import Flask
from iilib.util.logger_factory import get_logger
from iilib.handler.vault_settings_handler import VaultSettingsHandler

vault_handler = VaultSettingsHandler()
logging_config = vault_handler.config.get('logging', {})
log_type = logging_config.get('log_type', 'local')
log_level = logging_config.get('log_level', 'INFO')

app = Flask(__name__)
app.config['DEBUG'] = True

@app.route('/')
def index():
    return "Flask is running in development mode"

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=True)
