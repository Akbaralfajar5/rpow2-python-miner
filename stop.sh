#!/bin/bash
# Stop rpow2 Python miner

if ! screen -list | grep -q "rpow2"; then
    echo "⚠️  Mining is not running"
    exit 1
fi

echo "🛑 Stopping mining..."
screen -S rpow2 -X quit

sleep 2

if screen -list | grep -q "rpow2"; then
    echo "❌ Failed to stop mining"
    exit 1
else
    echo "✅ Mining stopped"
fi
