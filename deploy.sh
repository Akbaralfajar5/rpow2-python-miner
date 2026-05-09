#!/bin/bash
# Python Miner Deployment Script for Zo.computer

echo "🚀 Deploying Python rpow2 Miner..."

# Create directory
mkdir -p ~/rpow2-python-miner
cd ~/rpow2-python-miner

# Download miner script
cat > miner.py << 'MINER_EOF'
#!/usr/bin/env python3
"""
Custom rpow2 Python Miner
Fast setup, multi-threaded mining
"""

import requests
import hashlib
import time
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

class Rpow2Miner:
    def __init__(self, cookie, threads=2, timeout=30):
        self.cookie = cookie
        self.threads = threads
        self.timeout = timeout
        self.base_url = "https://api.rpow2.com"
        self.session = requests.Session()
        self.session.headers.update({
            'Cookie': cookie,
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        })
        self.stats = {
            'blocks_mined': 0,
            'errors': 0,
            'start_time': time.time()
        }
        self.lock = threading.Lock()
    
    def log(self, msg, level="INFO"):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] [{level}] {msg}", flush=True)
    
    def get_challenge(self):
        """Get mining challenge from API"""
        try:
            resp = self.session.post(f"{self.base_url}/challenge", timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                return data.get('challenge_id'), data.get('nonce_prefix'), data.get('difficulty_bits', 25)
            else:
                self.log(f"Failed to get challenge: {resp.status_code}", "ERROR")
                return None, None, None
        except Exception as e:
            self.log(f"Challenge error: {e}", "ERROR")
            return None, None, None
    
    def find_nonce(self, nonce_prefix, difficulty, start_nonce, end_nonce):
        """Find valid nonce for challenge"""
        # Convert hex prefix to bytes
        prefix_bytes = bytes.fromhex(nonce_prefix)
        
        for nonce in range(start_nonce, end_nonce):
            # Create hash: prefix + nonce (little endian)
            data = prefix_bytes + nonce.to_bytes(8, byteorder='little')
            hash_result = hashlib.sha256(data).digest()
            
            # Count trailing zero bits
            trailing_zeros = 0
            for byte in reversed(hash_result):
                if byte == 0:
                    trailing_zeros += 8
                else:
                    # Count trailing zeros in this byte
                    trailing_zeros += (byte & -byte).bit_length() - 1
                    break
            
            if trailing_zeros >= difficulty:
                return nonce
        
        return None
    
    def submit_nonce(self, challenge_id, nonce):
        """Submit found nonce to API"""
        try:
            payload = {
                'challenge_id': challenge_id,
                'solution_nonce': str(nonce)
            }
            resp = self.session.post(f"{self.base_url}/mint", json=payload, timeout=10)
            
            if resp.status_code == 200:
                return True, "Minted!"
            else:
                return False, f"Mint failed ({resp.status_code}): {resp.text[:100]}"
        except Exception as e:
            return False, f"Submit error: {e}"
    
    def mine_block(self):
        """Mine a single block"""
        # Get challenge
        challenge_id, nonce_prefix, difficulty = self.get_challenge()
        if not challenge_id:
            with self.lock:
                self.stats['errors'] += 1
            return False
        
        self.log(f"Challenge: {challenge_id[:16]}... | Difficulty: {difficulty} bits")
        
        # Find nonce with multi-threading
        start_time = time.time()
        chunk_size = 100_000_000  # 100M nonces per thread
        
        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = []
            for i in range(self.threads):
                start = i * chunk_size
                end = start + chunk_size
                future = executor.submit(self.find_nonce, nonce_prefix, difficulty, start, end)
                futures.append(future)
            
            # Wait for first valid nonce
            for future in as_completed(futures):
                nonce = future.result()
                if nonce is not None:
                    # Cancel other threads
                    for f in futures:
                        f.cancel()
                    
                    elapsed = time.time() - start_time
                    self.log(f"Found nonce: {nonce} in {elapsed:.2f}s")
                    
                    # Submit nonce
                    success, msg = self.submit_nonce(challenge_id, nonce)
                    if success:
                        with self.lock:
                            self.stats['blocks_mined'] += 1
                        self.log(f"✓ {msg} | Session: {self.stats['blocks_mined']}", "SUCCESS")
                        return True
                    else:
                        self.log(msg, "ERROR")
                        with self.lock:
                            self.stats['errors'] += 1
                        return False
        
        self.log("No nonce found in range", "WARN")
        return False
    
    def run(self):
        """Main mining loop"""
        self.log(f"Starting rpow2 Python miner with {self.threads} threads")
        
        while True:
            try:
                self.mine_block()
                time.sleep(1)  # Small delay between blocks
            except KeyboardInterrupt:
                self.log("Mining stopped by user", "INFO")
                self.print_stats()
                break
            except Exception as e:
                self.log(f"Unexpected error: {e}", "ERROR")
                with self.lock:
                    self.stats['errors'] += 1
                time.sleep(5)
    
    def print_stats(self):
        """Print mining statistics"""
        elapsed = time.time() - self.stats['start_time']
        hours = elapsed / 3600
        blocks_per_hour = self.stats['blocks_mined'] / hours if hours > 0 else 0
        
        print("\n" + "="*50)
        print("Mining Statistics")
        print("="*50)
        print(f"Blocks mined: {self.stats['blocks_mined']}")
        print(f"Errors: {self.stats['errors']}")
        print(f"Runtime: {elapsed/60:.1f} minutes")
        print(f"Rate: {blocks_per_hour:.1f} blocks/hour")
        print("="*50 + "\n")


def main():
    # Read cookie from accounts.txt
    try:
        with open('accounts.txt', 'r') as f:
            cookie = f.read().strip()
    except FileNotFoundError:
        print("ERROR: accounts.txt not found!")
        print("Create accounts.txt with your rpow_session cookie")
        sys.exit(1)
    
    # Get threads from command line or default to 2
    threads = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    
    # Start miner
    miner = Rpow2Miner(cookie, threads=threads)
    miner.run()


if __name__ == "__main__":
    main()
MINER_EOF

chmod +x miner.py

# Add Account 1 cookie
echo 'rpow_session=eyJlbWFpbCI6ImFrYmFyYWxwYWphcjVAZ21haWwuY29tIiwiZXhwIjoxNzgwODQzNjU4fQ.GShkyCeG_9TMhkFL5uLua5iPDmWm_xlWNhTpup3trtU' > accounts.txt

# Create start script
cat > start.sh << 'START_EOF'
#!/bin/bash
if screen -list | grep -q "rpow2"; then
    echo "Mining already running"
    exit 1
fi
THREADS=$(nproc)
echo "Starting Python miner with $THREADS threads..."
screen -dmS rpow2 python3 miner.py $THREADS
sleep 2
echo "✓ Mining started"
START_EOF

chmod +x start.sh

# Create stop script
cat > stop.sh << 'STOP_EOF'
#!/bin/bash
screen -S rpow2 -X quit && echo "✓ Mining stopped"
STOP_EOF

chmod +x stop.sh

# Create status script
cat > status.sh << 'STATUS_EOF'
#!/bin/bash
echo "=========================================="
echo "rpow2 Python Miner Status"
echo "=========================================="
if screen -list | grep -q "rpow2"; then
    echo "✓ Mining is RUNNING"
    echo ""
    screen -S rpow2 -X hardcopy /tmp/rpow2_screen.txt
    tail -20 /tmp/rpow2_screen.txt 2>/dev/null || echo "No logs yet"
else
    echo "✗ Mining is NOT running"
fi
STATUS_EOF

chmod +x status.sh

echo ""
echo "✅ Python miner deployed!"
echo ""
echo "Commands:"
echo "  ./start.sh   # Start mining"
echo "  ./stop.sh    # Stop mining"
echo "  ./status.sh  # Check status"
echo ""
