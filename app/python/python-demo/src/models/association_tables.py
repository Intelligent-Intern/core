from sqlalchemy import Table, Column, Integer, ForeignKey
from utils.database import Base

# Many-to-many association table between IssueType and Page
issue_page_association = Table(
    'issue_page_association',
    Base.metadata,
    Column('issue_type_id', Integer, ForeignKey('issue_types.id', ondelete="CASCADE")),
    Column('page_id', Integer, ForeignKey('pages.id', ondelete="CASCADE")),
    extend_existing=True  # This allows extending the existing table definition
)
