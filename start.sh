#!/bin/bash
# Start rpow2 Python miner

if screen -list | grep -q "rpow2"; then
    echo "⚠️  Mining already running"
    echo "Use: screen -r rpow2  (to attach)"
    exit 1
fi

# Auto-detect CPU cores
THREADS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

echo "🚀 Starting Python miner with $THREADS threads..."
screen -dmS rpow2 python3 miner.py $THREADS

sleep 2

if screen -list | grep -q "rpow2"; then
    echo "✅ Mining started successfully!"
    echo ""
    echo "Commands:"
    echo "  ./status.sh       - Check status"
    echo "  screen -r rpow2   - Attach to session (Ctrl+A then D to detach)"
    echo "  ./stop.sh         - Stop mining"
else
    echo "❌ Failed to start mining"
    exit 1
fi
