from sqlalchemy import Column, Integer, ForeignKey, Text
from utils.database import Base
from sqlalchemy.orm import relationship

class Headline(Base):
    __tablename__ = 'headlines'

    id = Column(Integer, primary_key=True, index=True)
    issue_type_id = Column(Integer, ForeignKey('issue_types.id'))
    headline_text = Column(Text, nullable=False)

    issue_type = relationship('IssueType', back_populates='headlines')
