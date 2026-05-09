#!/bin/bash
# Auto-deploy and auto-run rpow2 Python miner on zo.computer

echo "🚀 Auto-deploying rpow2 Python miner..."

# Deploy miner
curl -sSL https://raw.githubusercontent.com/Akbaralfajar5/rpow2-python-miner/main/deploy.sh | bash

# Go to miner directory
cd ~/rpow2-python-miner

# Create auto-start watchdog script
cat > watchdog.sh << 'WATCHDOG_EOF'
#!/bin/bash
# Auto-start watchdog for rpow2 miner

while true; do
    # Check if mining is running
    if ! screen -list | grep -q "rpow2"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mining not running, checking API..."
        
        # Check API status
        API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.rpow2.com/challenge)
        
        if [ "$API_STATUS" = "200" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] API UP! Starting miner..."
            ./start.sh
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] API still down ($API_STATUS), waiting..."
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mining is running"
    fi
    
    # Wait 5 minutes
    sleep 300
done
WATCHDOG_EOF

chmod +x watchdog.sh

# Start watchdog in background
echo "🤖 Starting auto-start watchdog..."
screen -dmS rpow2-watchdog bash -c "cd ~/rpow2-python-miner && ./watchdog.sh"

echo ""
echo "✅ Auto-deploy complete!"
echo ""
echo "Watchdog is running in background:"
echo "  - Checks API every 5 minutes"
echo "  - Auto-starts mining when API is UP"
echo "  - Auto-restarts if crashed"
echo ""
echo "Commands:"
echo "  screen -r rpow2-watchdog  # View watchdog logs"
echo "  screen -r rpow2           # View mining logs (when running)"
echo "  cd ~/rpow2-python-miner && ./status.sh  # Check status"
echo ""
