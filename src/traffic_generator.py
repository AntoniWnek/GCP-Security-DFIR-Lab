import requests
import random
import time

# Browser set (Windows, macOS, Linux)
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"
]

# Paths on DVWA
PATHS = [
    "/login.php",
    "/index.php", 
    "/about.php", 
    "/vulnerabilities/brute/", 
    "/vulnerabilities/sqli/", 
    "/vulnerabilities/xss_r/"
]

# Database for POST requests
CREDENTIALS = {
    "admin": "admin",
    "admin123": "admin123",
    "user": "user",
    "test": "test"
}

TARGET_IP = "BASTIONIP"
base_url = f"http://{TARGET_IP}"

print("[*] Starting Benign Traffic Generator...")

while True:
    chosen_path = random.choice(PATHS)
    chosen_agent = random.choice(USER_AGENTS)
    target_url = base_url + chosen_path
    
    # POST or GET draw 
    if random.randint(1, 10) <= 2:
        try:
            requests.post(target_url, data=CREDENTIALS, headers={"User-Agent": chosen_agent}, timeout=5)
            print(f"[POST] Login attempt at: {target_url}")
        except requests.exceptions.RequestException:
            print(f"[!] Connection error with {target_url}")
    else:
        try:
            requests.get(target_url, headers={"User-Agent": chosen_agent}, timeout=5)
            print(f"[GET] Visited: {target_url}")
        except requests.exceptions.RequestException:
            print(f"[!] Connection error with {target_url}")
 
    time.sleep(random.randint(3, 10))
