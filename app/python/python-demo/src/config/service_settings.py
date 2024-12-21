# config/service_settings.py

SERVICE_CONFIG_OVERRIDES = {
    'logging': {
        'log_type': 'local',  # log-type ('local', 'loki', 'graylog')
        'log_level': 'debug',  # log-level ('debug', 'info', 'warning')
        'local': {
            'log_file': '',
            'max_log_size': '',
            'backup_count': '',
        },
        'loki': {
            'url': '',
            'username': '',
            'password': '',
            'log_level': '',
        },
        'graylog': {
            'url': '',
            'api_key': '',
            'log_level': '',
        },
    },
    'openai': {
        'api_key': '',
        'api_url': '',
        'model': ''
    },
    'azure': {
        'api_key': '',
        'api_url': '',
        'tenant_id': '',
        'client_id': '',
        'client_secret': ''
    }
}
