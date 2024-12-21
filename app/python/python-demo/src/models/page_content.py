from sqlalchemy import Column, String, Integer, ForeignKey, UniqueConstraint
from utils.database import Base

class PageContent(Base):
    __tablename__ = 'page_content'

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String, ForeignKey('document_metadata.uuid'))
    page_number = Column(Integer)
    content = Column(String)
    room_name = Column(String)

    __table_args__ = (
        UniqueConstraint('uuid', 'page_number'),
    )
