# Star-Trek-Data

```{python}
import os
import time
import random
import hashlib
import requests
from bs4 import BeautifulSoup as BS
import string
import nltk
from nltk.corpus import stopwords
from collections import Counter
import csv

# Download necessary NLTK resources
nltk.download('punkt')
nltk.download('stopwords')

# Set of English stopwords
stop_words = set(stopwords.words('english'))

CACHE_DIR = "page_cache"

# Create the cache directory if it doesn't exist
if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)
```
