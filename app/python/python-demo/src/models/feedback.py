from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from utils.database import Base
from utils.time_helpers import utc_now

class Feedback(Base):
    __tablename__ = 'feedback'

    id = Column(Integer, primary_key=True, autoincrement=True)
    uuid = Column(String, ForeignKey('document_metadata.uuid'), nullable=False)
    feedback_text = Column(String, nullable=False)
    timestamp = Column(DateTime, default=utc_now)
