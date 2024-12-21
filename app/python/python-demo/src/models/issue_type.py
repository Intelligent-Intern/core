from sqlalchemy import Column, String, Integer, ForeignKey, Text
from utils.database import Base
from sqlalchemy.orm import relationship
from models.association_tables import issue_page_association  # Import from association_tables

class IssueType(Base):
    __tablename__ = 'issue_types'

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(String, ForeignKey('document_metadata.uuid'))
    issue_type = Column(String)
    description = Column(Text)

    # Many-to-many relationship with Page
    pages = relationship('Page', secondary=issue_page_association, back_populates='issues')

    # Relationship with Headline
    headlines = relationship('Headline', back_populates='issue_type', cascade="all, delete-orphan")
