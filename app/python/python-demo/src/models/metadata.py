from sqlalchemy import Column, String, Integer, DateTime
from utils.database import Base
from utils.time_helpers import utc_now

class DocumentMetaData(Base):
    __tablename__ = 'document_metadata'
    uuid = Column(String, primary_key=True, index=True)
    original_name = Column(String)
    num_pages = Column(Integer)
    date_uploaded = Column(DateTime, default=utc_now)
    date_processed = Column(DateTime)
    status = Column(String)
