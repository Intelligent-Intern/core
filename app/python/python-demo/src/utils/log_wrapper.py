# utils/log_wrapper.py
import logging
import uuid
from datetime import datetime
from io import BytesIO
from minio import Minio
import os

# Initialize MinIO client
MINIO_URL = "minio:9000"
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minio")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minio123")

minio_client = Minio(
    MINIO_URL,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=False
)

# Ensure buckets exist
for bucket in ["infologs", "warninglogs", "errorlogs"]:
    if not minio_client.bucket_exists(bucket):
        minio_client.make_bucket(bucket)

class MinioLogHandler(logging.Handler):
    def emit(self, record):
        log_entry = self.format(record)
        log_level = record.levelname.lower()
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        filename = f"{timestamp}_{uuid.uuid4()}.log"
        bucket_name = f"{log_level}logs"

        try:
            # Convert log entry to BytesIO for MinIO
            log_data = BytesIO(log_entry.encode('utf-8'))
            minio_client.put_object(
                bucket_name,
                filename,
                data=log_data,
                length=log_data.getbuffer().nbytes
            )
        except Exception as e:
            print(f"Failed to upload log to MinIO: {e}")

def get_logger(name):
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    # Add the MinioLogHandler if it's not already added
    if not any(isinstance(handler, MinioLogHandler) for handler in logger.handlers):
        minio_handler = MinioLogHandler()
        minio_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
        logger.addHandler(minio_handler)

    return logger