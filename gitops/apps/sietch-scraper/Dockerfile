# Use a specific version of python as a base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies required for Chromium and Selenium
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source code
COPY ./src .

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["python", "-u", "scraper.py"] 