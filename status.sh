#!/bin/bash
# Check rpow2 Python miner status

echo "=========================================="
echo "rpow2 Python Miner Status"
echo "=========================================="
echo ""

if screen -list | grep -q "rpow2"; then
    echo "✅ Mining is RUNNING"
    echo ""
    echo "Recent logs (last 15 lines):"
    echo "----------------------------------------"
    
    # Capture screen output
    screen -S rpow2 -X hardcopy /tmp/rpow2_screen.txt
    
    if [ -f /tmp/rpow2_screen.txt ]; then
        tail -15 /tmp/rpow2_screen.txt
    else
        echo "No logs available yet"
    fi
    
    echo ""
    echo "Commands:"
    echo "  screen -r rpow2   - Attach to session"
    echo "  ./stop.sh         - Stop mining"
else
    echo "❌ Mining is NOT running"
    echo ""
    echo "Start mining with: ./start.sh"
fi

echo ""
echo "=========================================="
