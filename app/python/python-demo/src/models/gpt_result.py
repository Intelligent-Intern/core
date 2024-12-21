from sqlalchemy import Column, String, Integer, ForeignKey, Text, DateTime
from utils.database import Base
from utils.time_helpers import utc_now

class GPTResult(Base):
    __tablename__ = 'gpt_results'

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String, ForeignKey('document_metadata.uuid'))
    issue_type_id = Column(Integer, ForeignKey('issue_types.id'))

    # New: fields for storing GPT API communication details
    request_payload = Column(Text, nullable=False)
    response_payload = Column(Text, nullable=False)
    total_tokens = Column(Integer, nullable=False)
    timestamp = Column(DateTime, default=utc_now)

    # Removed headline and description fields as they are not needed anymore
