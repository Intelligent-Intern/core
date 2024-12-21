from sqlalchemy import Column, Integer, String, ForeignKey
from utils.database import Base
from sqlalchemy.orm import relationship
from models.association_tables import issue_page_association  # Import from association_tables

class Page(Base):
    __tablename__ = 'pages'

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String, ForeignKey('document_metadata.uuid', ondelete='CASCADE'))
    page_number = Column(Integer, nullable=False)

    # Many-to-many relationship with IssueType
    issues = relationship('IssueType', secondary=issue_page_association, back_populates='pages')

