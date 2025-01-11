# config/service_settings.py

SERVICE_CONFIG_OVERRIDES = {
 "logging": {
   "log_type": "loki",
   "config": {
     "url": "http://custom-loki:3100/loki/api/v1/push",
     "tenant": "custom_tenant",
     "username": "custom_user",
     "password": "custom_password",
     "log_level": "info"
   }
 },
 "azure_openai": {
   "provider": "azure",
   "model": "gpt-4",
   "api_key": "custom-azure-key",
   "endpoint": "https://custom-endpoint.openai.azure.com",
   "deployment_id": "custom-deployment",
   "max_tokens": 1500,
   "temperature": 0.9
 },
 "openai": {
   "provider": "openai",
   "model": "gpt-3.5-turbo",
   "api_key": "custom-openai-key",
   "max_tokens": 1000,
   "temperature": 0.8
 },
 "file": {
   "filepath": "/var/log/custom-app.log",
   "log_level": "debug"
 }
}