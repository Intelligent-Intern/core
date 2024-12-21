import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)


from sqlalchemy import create_engine, Column, Integer, ForeignKey, String, Text, Table
from sqlalchemy.orm import declarative_base, sessionmaker
from settings.config import DATABASE_URL


# Create the engine and session
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Many-to-many association table
issue_page_association = Table(
    'issue_page_association',
    Base.metadata,
    Column('issue_type_id', Integer, ForeignKey('issue_types.id')),
    Column('page_id', Integer, ForeignKey('pages.id'))
)

def init_db():
    from models.metadata import DocumentMetaData
    from models.issue_type import IssueType
    from models.page import Page
    from models.association_tables import issue_page_association
    from models.api_log import APILog

    Base.metadata.create_all(bind=engine)
