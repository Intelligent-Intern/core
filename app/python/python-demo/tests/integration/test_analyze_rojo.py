import warnings
import time
import os
import pytest
from app import app
from utils.database import SessionLocal
from models.page_content import PageContent
from models.issue_type import IssueType
from models.headline import Headline

warnings.filterwarnings("ignore", category=DeprecationWarning)

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_analyze_rojo(client):
    """Test the full integration: upload, process, and analyze PDF with polling."""
    base_path = os.path.abspath(os.getenv('BASE_PATH', './'))
    test_pdf_path = os.path.join(base_path, '..', 'var', 'test', 'data', 'test1.pdf')
    assert os.path.exists(test_pdf_path), "Test PDF file not found."
    with open(test_pdf_path, 'rb') as pdf_file:
        data = {'file': (pdf_file, 'test1.pdf')}
        response = client.post('/upload', data=data, content_type='multipart/form-data')
    assert response.status_code == 200, f"Upload failed: {response.data}"
    json_data = response.get_json()
    unique_id = json_data.get("uuid")
    assert unique_id, "No unique_id returned from upload endpoint"
    time.sleep(4)
    file_ready = False
    for _ in range(10):
        poll_response = client.get('/check-output', query_string={'uuid': unique_id})
        assert poll_response.status_code == 200, "Polling failed"
        if poll_response.get_json().get("fileExists"):
            file_ready = True
            break
        time.sleep(2)
    assert file_ready, "Processed PDF was not ready after polling"
    session = SessionLocal()
    try:
        total_pages = session.query(PageContent).filter_by(uuid=unique_id).count()
        assert total_pages > 0, "No pages found after processing the PDF."
        issues = session.query(IssueType).filter_by(uuid=unique_id).all()
        assert len(issues) > 0, "No issues found after ROJO analysis."
        for issue in issues:
            headlines = session.query(Headline).filter_by(issue_type_id=issue.id).all()
            assert len(headlines) > 0, f"No headlines found for issue {issue.id}"
            for headline in headlines:
                assert headline.headline_text != "No headlines found", f"Headline {headline.id} has 'No headlines found' text."
    finally:
        session.close()
