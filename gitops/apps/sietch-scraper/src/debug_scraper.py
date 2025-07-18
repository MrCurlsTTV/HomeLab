import time
import pprint
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import os

# URL to scrape
URL = "https://dune.gaming.tools/server-status"

def get_chrome_driver():
    """Set up and return a Chrome WebDriver instance."""
    chrome_options = Options()
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    # Use Chromium if available
    if os.path.exists('/usr/bin/chromium'):
        chrome_options.binary_location = '/usr/bin/chromium'

    try:
        # Try to use a system chromedriver if it exists
        if os.path.exists('/usr/bin/chromedriver'):
            service = Service('/usr/bin/chromedriver')
        else:
            # Fallback to webdriver_manager
            print("System chromedriver not found, using webdriver-manager.")
            service = Service(ChromeDriverManager().install())
        
        driver = webdriver.Chrome(service=service, options=chrome_options)
        return driver
    except Exception as e:
        print(f"Error setting up any ChromeDriver: {e}")
        raise

def scrape_live_data(url):
    """Scrape the live website and return the data."""
    driver = None
    try:
        print("Initializing Chrome WebDriver...")
        driver = get_chrome_driver()
        
        print(f"Navigating to {url}...")
        driver.get(url)
        
        print("Waiting for content to load...")
        try:
            WebDriverWait(driver, 20).until(
                EC.presence_of_element_located((By.CLASS_NAME, "text-2xl"))
            )
        except Exception as e:
            print(f"Timeout waiting for primary content, page might have loaded anyway. Error: {e}")
        
        time.sleep(5)
        
        print("Parsing page content...")
        html_content = driver.execute_script("return document.documentElement.outerHTML;")
        soup = BeautifulSoup(html_content, 'html.parser')
        
        servers_data = []
        
        server_headers = soup.select('div.border-slate-700.flex.justify-between')
        print(f"\nFound {len(server_headers)} server headers.")
        
        if server_headers:
            for header in server_headers:
                try:
                    server_name_elem = header.select_one('div.text-2xl')
                    region_elem = header.select_one('div.text-xl')
                    
                    if not server_name_elem or not region_elem:
                        continue
                    
                    server_name = server_name_elem.text.strip()
                    region = region_elem.text.strip()
                    
                    table = header.find_next_sibling('table', class_='datatable')
                    if not table:
                        continue
                    
                    sietches = []
                    rows = table.select('tbody tr')
                    
                    for row in rows:
                        cols = row.find_all('td')
                        if len(cols) < 2:
                            continue
                        
                        sietch_name = cols[0].text.strip()
                        if sietch_name.lower() == 'total':
                            continue
                        
                        player_count_text = cols[1].text.strip()
                        
                        try:
                            current, max_p = map(int, player_count_text.split('/'))
                            sietches.append({'name': sietch_name, 'player_count': current, 'max_players': max_p})
                        except (ValueError, IndexError):
                            continue
                    
                    if sietches:
                        servers_data.append({'name': server_name, 'region': region, 'sietches': sietches})
                        print(f"Processed server: {server_name} ({region}) with {len(sietches)} sietches.")
                
                except Exception as e:
                    print(f"Error processing a server section: {e}")
                    continue
        
        return servers_data
        
    except Exception as e:
        print(f"An error occurred in scrape_live_data: {e}")
        return None
        
    finally:
        if driver:
            print("Closing Chrome WebDriver...")
            driver.quit()

def main():
    """Main function to run the debug scraper with live data."""
    print("--- Starting Scraper Debug Script (Live Data) ---")
    data = scrape_live_data(URL)
    
    if data:
        print("\n--- Scraping Successful ---")
        print("Extracted Data:")
        pprint.pprint(data)
    else:
        print("\n--- Scraping Failed ---")
        print("No data was returned.")
    
    print("\n--- Debug Script Finished ---")

if __name__ == "__main__":
    main() 