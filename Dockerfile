# Use the rocker/verse image as the base
FROM rocker/verse:latest

# Install Python and necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the Python script into the container
COPY pyscript.py /pyscript.py

# Install required Python packages
RUN pip3 install requests beautifulsoup4 nltk jupyter

# Download necessary NLTK resources, including punkt_tab
RUN python3 -m nltk.downloader punkt stopwords punkt_tab

# Install additional R packages not included in rocker/verse
RUN R -e "install.packages(c('pROC', 'R.matlab', 'ppclust', 'mclust', 'rdist', 'gbm'), repos='http://cran.rstudio.com/')"

# Expose the Jupyter Notebook port
EXPOSE 8989
EXPOSE 8181

# Set the default command to start Jupyter Notebook on port 8989
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8181", "--no-browser", "--allow-root"]


