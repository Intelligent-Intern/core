import re
import unicodedata

def normalize_text(text):
    return unicodedata.normalize('NFKD', text).encode('ASCII', 'ignore').decode('utf-8')

def clean_issue_type(issue_type):
    cleaned_issue_type = re.sub(r'^\d+\s+', '', issue_type)
    return normalize_text(cleaned_issue_type.lower()).capitalize()
