# rpow2 Python Miner

Fast, lightweight Python miner for rpow2 cryptocurrency.

## Features

- ✅ **No compilation needed** - Pure Python, instant deployment
- ✅ **Multi-threaded** - Auto-detects CPU cores
- ✅ **Fast performance** - ~1-2s per block (comparable to Rust)
- ✅ **Easy setup** - One-liner deployment
- ✅ **Cross-platform** - Works on Linux, macOS, Windows

## Quick Start

### Auto-Deploy with Watchdog (Recommended)

Automatically deploys, monitors API status, and starts mining when API is UP:

```bash
curl -sSL https://raw.githubusercontent.com/Akbaralfajar5/rpow2-python-miner/main/auto-deploy.sh | bash
```

### Manual Deployment

```bash
curl -sSL https://raw.githubusercontent.com/Akbaralfajar5/rpow2-python-miner/main/deploy.sh | bash
```

### Manual Setup

1. Clone repository:
```bash
git clone https://github.com/Akbaralfajar5/rpow2-python-miner.git
cd rpow2-python-miner
```

2. Add your rpow2 session cookie to `accounts.txt`:
```bash
echo 'rpow_session=YOUR_COOKIE_HERE' > accounts.txt
```

3. Start mining:
```bash
./start.sh
```

## Commands

- `./start.sh` - Start mining in background
- `./stop.sh` - Stop mining
- `./status.sh` - Check mining status

## Requirements

- Python 3.6+
- `requests` library (auto-installed)
- `screen` (for background mining)

## Performance

- **Speed:** 1-2 seconds per block
- **CPU Usage:** Scales with available cores
- **Memory:** ~50MB per instance

## How It Works

1. Fetches mining challenge from rpow2 API
2. Multi-threaded nonce search (SHA256 + trailing zeros)
3. Submits valid nonce to mint tokens
4. Repeats continuously

## Configuration

Edit `miner.py` to customize:
- `threads` - Number of mining threads (default: auto-detect)
- `chunk_size` - Nonce search range per thread (default: 100M)

## Troubleshooting

**Mining not starting?**
```bash
# Check if screen is installed
which screen

# Check logs
./status.sh
```

**API errors?**
- Check your cookie is valid
- Verify network connectivity
- API may be temporarily down

## License

MIT License - Free to use and modify

## Credits

Built by Akbar Alfajar (@Akbaralfajar5)
