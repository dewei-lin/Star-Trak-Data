# Explaning Py Code

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

```{python}
def md5_hash(url):
    """Returns the MD5 hash of a given URL."""
    return hashlib.md5(url.encode()).hexdigest()
```
This function takes an url and returns a numeric value linked to url, my intuition is that it makes the data for url shorter when we store it.

```{python}
def cache_path(url):
    """Returns the cache file path for a given URL."""
    return os.path.join(CACHE_DIR, md5_hash(url))
```

This function stores the encoded url in our cache directory, making it more efficient to sort the urls.

```{python}
def fetch_raw(url):
    """Fetches the page content from the web without caching."""
    headers = {
        "User-Agent": "curl/7.68.0",  # Mimic the curl request
        "Accept-Language": "en-US,en;q=0.5"
    }
    
    # Print the current time in HH:MM:SS AM/PM format before each fetch
    print(f"Fetching {url} at {time.strftime('%I:%M:%S %p')}")

    try:
        time.sleep(random.uniform(6, 12))  # Random delay to avoid hammering the server
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.text
        else:
            print(f"Failed to fetch {url} with status code {response.status_code}")
            return None
    except requests.RequestException as e:
        print(f"Error fetching {url}: {e}")
        return None
```

This function fetches HTML web page contents for the given URL with a delay between two fetching.

```{python}
def fetch(url):
    """Wrapper function that implements caching around the raw fetch."""
    cache_file = cache_path(url)
    
    # Check if the page is cached
    if os.path.exists(cache_file):
        with open(cache_file, 'r', encoding='utf-8') as file:
            print(f"Loading cached page for {url}")
            return BS(file.read(), "html.parser")
    
    # If not cached, fetch the raw page and cache it
    page_content = fetch_raw(url)
    if page_content:
        with open(cache_file, 'w', encoding='utf-8') as file:
            file.write(page_content)
        return BS(page_content, "html.parser")
    else:
        return None
```

The function operates under the condition whether the page is cached. If it's cached, it will red the HTML and extract the text from the web page with Beatuifulsoup; If it's not cached, the function will cache it and use raw fetch function above and fetch the data.

```{python}
def episode_list_urls():
    """Fetches URLs of episodes from the main episode list page."""
    source_url = "http://www.chakoteya.net/NextGen/episodes.htm"
    bs = fetch(source_url)
    urls = []
    for tb in bs.find_all("tbody"):
        for anchor in tb.find_all("a"):
            urls.append(f"http://www.chakoteya.net/NextGen/{anchor.attrs['href']}")
    return urls
```
The function stores all the urls in source_url into a list.

```{python}
def tokenize_and_count(text):
    """Tokenizes the text, removes punctuation, stopwords, downcases, and counts word frequencies."""
    # Remove punctuation and downcase
    text = text.translate(str.maketrans("", "", string.punctuation)).lower()

    # Tokenize the text
    tokens = nltk.word_tokenize(text)

    # Remove stop words
    filtered_tokens = [word for word in tokens if word not in stop_words]

    # Count the word frequencies
    word_counts = Counter(filtered_tokens)

    return word_counts
```
This function tokenizes the text and count the frequencies of each word that appeared in the text.

```{python}
def get_text_of_episodes():
    """Fetches and returns an array of objects with episode URLs and their text."""
    urls = episode_list_urls()
    episodes = []

    for url in urls:
        bs = fetch(url)
        b = bs.find("tbody")
        txt = b.text

        # Store the URL and text in an object (dictionary) for each episode
        episodes.append({
            "url": url,
            "text": txt
        })

    return episodes
```
The function utilizes the urls list obtained from the episode_list_urls() and create a dictionary that has the url and texts scrapped from the url.

```{python}
def get_word_counts_for_episodes(episodes):
    """Takes an array of episode objects and calculates word frequencies for each."""
    episode_word_counts = {}

    for episode in episodes:
        url = episode["url"]
        text = episode["text"]

        # Tokenize the text and count word frequencies
        word_counts = tokenize_and_count(text)

        # Store the word counts for each episode
        episode_word_counts[url] = word_counts

    return episode_word_counts
```


```{python}
def get_total_word_count(episode_word_counts):
    """Calculates the total word count across all episodes."""
    total_word_count = Counter()

    for word_counts in episode_word_counts.values():
        total_word_count.update(word_counts)

    return total_word_count
```
The function takes the dictionary that contains url and the associated test, and calculate the frequencies of each word in each url (the episode)

```{python}
def convert_to_word_count_vectors(episode_word_counts, filtered_words):
    """Converts word counts for each episode into a vector following the filtered word order."""
    word_vectors = {}

    for url, word_counts in episode_word_counts.items():
        # Create a vector for this episode by the order of filtered_words
        vector = [word_counts.get(word, 0) for word in filtered_words]
        word_vectors[url] = vector

    return word_vectors
```
This function transforms the dictionary into a data frame that the first column is url and rest columns are the words, rows are the frequencies.

```{python}
def write_word_counts_to_csv(word_count_vectors, filtered_words, filename="episode_word_counts.csv"):
    """Writes the episode word count vectors to a CSV file."""
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)

        # Write the header row (episode URL and each word)
        header = ['Episode URL'] + filtered_words
        writer.writerow(header)

        # Write each episode's word count vector
        for url, vector in word_count_vectors.items():
            row = [url] + vector
            writer.writerow(row)
```
This function writes out the csv file for further analysis.

```{python}
# Example usage to fetch episode texts, get word counts, and calculate total word count
episodes = get_text_of_episodes()
episode_word_counts = get_word_counts_for_episodes(episodes)

# Calculate total word count over all episodes
total_word_count = get_total_word_count(episode_word_counts)

# Filter words with a total count greater than 20 and sort by frequency
filtered_words = [word for word, count in total_word_count.items() if count > 20]

# Convert each episode's word counts into a vector of word counts
word_count_vectors = convert_to_word_count_vectors(episode_word_counts, filtered_words)

# Write the word count vectors to a CSV file
write_word_counts_to_csv(word_count_vectors, filtered_words)

print(f"Word counts written to 'episode_word_counts.csv'")
```
# R code and the output

Please download and read [R output HTML](https://github.com/dewei-lin/Star-Trak-Data/blob/main/rscript.html);

# Pandas output

```{ipynb}
import pandas as pd

data = pd.read_csv("episode_word_counts.csv")


row_count = len(data)
print(f"Total number of rows: {row_count}")


data['row_sum'] = data.select_dtypes(include='number').sum(axis=1)


data_filtered = data[data['row_sum'] >= 100]


data_filtered = data_filtered.drop(columns=['row_sum'])  
data_filtered.to_csv("filtered_episode_word_counts.csv", index=False)

print("Filtered data saved to 'filtered_episode_word_counts.csv'")
```
Output:
```plaintext
Total number of rows: 176
Filtered data saved to 'filtered_episode_word_counts.csv'
```
See the code in [pdscript.ipynb](https://github.com/dewei-lin/Star-Trak-Data/blob/main/pdscript.ipynb) and the output csv in [filtered_episode_word_counts.csv](https://github.com/dewei-lin/Star-Trak-Data/blob/main/filtered_episode_word_counts.csv).
