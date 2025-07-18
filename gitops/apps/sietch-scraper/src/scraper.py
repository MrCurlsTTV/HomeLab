import os
import time
from bs4 import BeautifulSoup
import psycopg2
from datetime import datetime
from dotenv import load_dotenv
from flask import Flask, jsonify
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

# Load environment variables
load_dotenv()

# Database connection parameters
DB_NAME = os.getenv('DB_NAME', 'sietch_tracker')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'postgres')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')

# URL to scrape
URL = "https://dune.gaming.tools/server-status"

app = Flask(__name__)

def get_chrome_driver():
    """Set up and return a Chrome WebDriver instance."""
    chrome_options = Options()
    chrome_options.add_argument('--headless')  # Run in headless mode
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    # Use Chromium instead of Chrome
    chrome_options.binary_location = '/usr/bin/chromium'
    
    try:
        # Try to use the system's chromedriver
        service = Service('/usr/bin/chromedriver')
        driver = webdriver.Chrome(service=service, options=chrome_options)
        return driver
    except Exception as e:
        print(f"Error setting up ChromeDriver with system binary: {e}")
        print("Attempting to use webdriver_manager as fallback...")
        try:
            service = Service(ChromeDriverManager().install())
            driver = webdriver.Chrome(service=service, options=chrome_options)
            return driver
        except Exception as e:
            print(f"Error setting up ChromeDriver with webdriver_manager: {e}")
            raise

def create_tables():
    """Create necessary database tables if they don't exist."""
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )
    cur = conn.cursor()
    
    # Create servers table with region column
    cur.execute("""
        CREATE TABLE IF NOT EXISTS servers (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) NOT NULL,
            region VARCHAR(50) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(name)
        )
    """)
    
    # Create sietches table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS sietches (
            id SERIAL PRIMARY KEY,
            server_id INTEGER REFERENCES servers(id),
            name VARCHAR(50) NOT NULL,
            player_count INTEGER,
            max_players INTEGER,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(server_id, name, timestamp)
        )
    """)
    
    conn.commit()
    cur.close()
    conn.close()

def scrape_data():
    """Scrape the website and return the data."""
    driver = None
    try:
        print("Initializing Chrome WebDriver...")
        driver = get_chrome_driver()
        
        print("Navigating to URL...")
        driver.get(URL)
        
        # Wait for content to load (wait for the first server name to appear)
        print("Waiting for content to load...")
        try:
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((By.CLASS_NAME, "text-2xl"))
            )
        except Exception as e:
            print(f"Timeout waiting for text-2xl element: {e}")
            print("Trying alternative approach...")
        
        # Give more time for JavaScript to render
        time.sleep(5)
        
        print("Parsing page content...")
        page_source = driver.page_source
        
        # Try executing JavaScript to get page content
        try:
            html_content = driver.execute_script("return document.documentElement.outerHTML;")
            print("\nSuccessfully executed JavaScript to get page content")
        except Exception as e:
            print(f"Error executing JavaScript: {e}")
            html_content = page_source
        
        # --- DEBUG: Save the HTML to a file ---
        try:
            with open("/app/debug.html", "w", encoding="utf-8") as f:
                f.write(html_content)
            print("Successfully saved HTML to /app/debug.html")
        except Exception as e:
            print(f"Error saving debug HTML file: {e}")
        # --- END DEBUG ---

        soup = BeautifulSoup(html_content, 'html.parser')
        
        servers_data = []
        
        # Find all server headers using the corrected, more specific selector.
        server_headers = soup.select('div.border-slate-700.flex.justify-between')
        print(f"\nFound {len(server_headers)} server headers.")
        
        if server_headers:
            print("\nProcessing server headers...")
            for header in server_headers:
                try:
                    # Extract server name and region from within the header
                    server_name_elem = header.select_one('div.text-2xl')
                    region_elem = header.select_one('div.text-xl')
                    
                    if not server_name_elem or not region_elem:
                        print("Could not find server name or region in a header, skipping.")
                        continue
                    
                    server_name = server_name_elem.text.strip()
                    region = region_elem.text.strip()
                    print(f"\nProcessing server: {server_name} ({region})")
                    
                    # The data table is the next sibling of the header element
                    table = header.find_next_sibling('table', class_='datatable')
                    if not table:
                        print(f"No data table found for server {server_name}")
                        continue
                    
                    sietches = []
                    # Process each row in the table body
                    rows = table.select('tbody tr')
                    
                    for row in rows:
                        cols = row.find_all('td')
                        if len(cols) >= 2:
                            sietch_name = cols[0].text.strip()
                            if sietch_name.lower() == 'total':  # Skip the summary row
                                continue
                            
                            player_count_text = cols[1].text.strip()
                            
                            try:
                                # Use map for a cleaner split/conversion
                                current_players, max_players = map(int, player_count_text.split('/'))
                                
                                sietches.append({
                                    'name': sietch_name,
                                    'player_count': current_players,
                                    'max_players': max_players
                                })
                                print(f"  Found sietch: {sietch_name} - {current_players}/{max_players}")
                            except (ValueError, IndexError) as e:
                                print(f"  Error parsing player count for {sietch_name}: {player_count_text} ({e})")
                                continue
                    
                    if sietches:
                        servers_data.append({
                            'name': server_name,
                            'region': region,
                            'sietches': sietches
                        })
                    
                except Exception as e:
                    print(f"An unexpected error occurred while processing a server section: {e}")
                    continue
        
        if not servers_data:
            print("\nNo data could be extracted.")
            return None
        
        return servers_data
        
    except Exception as e:
        print(f"Error scraping data: {e}")
        return None
        
    finally:
        if driver:
            print("Closing Chrome WebDriver...")
            driver.quit()

def store_data(data):
    """Store the scraped data in the database."""
    if not data:
        return
    
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )
    cur = conn.cursor()
    
    timestamp = datetime.now()
    
    for server in data:
        # Insert or get server
        cur.execute("""
            INSERT INTO servers (name, region)
            VALUES (%s, %s)
            ON CONFLICT (name) DO UPDATE 
            SET region = EXCLUDED.region
            RETURNING id
        """, (server['name'], server['region']))
        server_id = cur.fetchone()[0]
        
        # Insert sietch data
        for sietch in server['sietches']:
            cur.execute("""
                INSERT INTO sietches (server_id, name, player_count, max_players, timestamp)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (server_id, name, timestamp) DO UPDATE 
                SET player_count = EXCLUDED.player_count,
                    max_players = EXCLUDED.max_players
            """, (server_id, sietch['name'], sietch['player_count'], sietch['max_players'], timestamp))
    
    conn.commit()
    cur.close()
    conn.close()

@app.route('/scrape', methods=['GET'])
def scrape_endpoint():
    """Scrape data, store it, and return it."""
    print(f"\nScraping data at {datetime.now()}")
    data = scrape_data()
    if data:
        store_data(data)
        print("Data successfully stored in database")
        return jsonify(data), 200
    else:
        print("Failed to scrape data")
        return jsonify({"status": "error", "message": "Failed to scrape data."}), 500

def main():
    """Main function to run the scraper as a web server."""
    print("Creating database tables...")
    create_tables()
    app.run(host='0.0.0.0', port=5000)

if __name__ == "__main__":
    main() 