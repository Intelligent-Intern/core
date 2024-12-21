import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

import unittest
import os
from werkzeug.datastructures import FileStorage
from services.process_upload import handle_pdf_upload
from utils.database import SessionLocal, init_db
from models.metadata import DocumentMetaData
from utils.database import init_db

class TestPDFUploadHandler(unittest.TestCase):

    def setUp(self):
        # Initialize a real database session
        self.session = SessionLocal()

    def tearDown(self):
        # Close the database session
        self.session.close()

    def test_handle_pdf_upload(self):
        init_db()

        # Base path setup to support relative paths in both Docker and local environments
        base_path = os.path.abspath(os.getenv('BASE_PATH', './'))

        # Path to the test PDF file
        test_pdf_path = os.path.join(base_path, '..', 'var', 'test', 'data', 'test1.pdf')

        # Simulating the uploaded file using FileStorage
        with open(test_pdf_path, 'rb') as f:
            file_storage = FileStorage(stream=f, filename='test1.pdf', content_type='application/pdf')
            file_storage_dict = {'file': file_storage}

            try:
                # Call the function and get the UUID
                unique_id = handle_pdf_upload(file_storage_dict)
                print(f"Generated UUID: {unique_id}")

                # Assertions to verify behavior
                self.assertIsInstance(unique_id, str)

                # Verify the metadata entry in the database
                metadata_entry = self.session.query(DocumentMetaData).filter_by(uuid=unique_id).first()
                self.assertIsNotNone(metadata_entry)
                self.assertEqual(metadata_entry.original_name, 'test1.pdf')
                self.assertEqual(metadata_entry.status, 'uploaded')

                # Clean up - Remove the created file
                uploaded_file_path = os.path.join(base_path, '..', 'var', 'input', f'{unique_id}.pdf')
                if os.path.exists(uploaded_file_path):
                    os.remove(uploaded_file_path)

                # Clean up - Delete the metadata entry from the database
                #self.session.delete(metadata_entry)
                #self.session.commit()

            except Exception as e:
                self.fail(f"handle_pdf_upload raised an unexpected exception: {e}")

if __name__ == '__main__':
    unittest.main()
