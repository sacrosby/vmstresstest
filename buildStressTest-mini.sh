#!/bin/bash
# VMware Workstation Burn-in Test Script (Laptop-friendly)
# Configures Ubuntu VM for light hardware stress testing

set -e

echo "=================================="
echo "VMware Workstation Test Setup"
echo "=================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "[1/4] Updating system and installing stress tools..."
apt update && apt upgrade -y
apt install -y stress-ng fio htop

echo ""
echo "[2/4] Creating stress test directory..."
mkdir -p /mnt/iotest

echo ""
echo "[3/4] Creating laptop-friendly stress script..."
cat > /root/stress-test.sh << 'EOF'
#!/bin/bash
# Light stress test - won't crash your laptop
echo "Starting stress test on $(hostname) at $(date)"

# CPU: use all cores at 70% (leaves headroom)
stress-ng --cpu $(nproc) --cpu-load 70 --timeout 600s &
echo "CPU stress started (PID: $!) - 70% load for 10 minutes"

# Memory: use 3GB of 4GB (leaves 1GB for OS)
stress-ng --vm 2 --vm-bytes 1500M --timeout 600s &
echo "Memory stress started (PID: $!) - 3GB for 10 minutes"

# Disk: light random I/O (5GB test file, lower queue depth)
fio --name=test --directory=/mnt/iotest --size=5G \
    --rw=randrw --bs=4k --direct=1 --numjobs=2 \
    --ioengine=libaio --iodepth=8 --runtime=600 --time_based &
echo "Disk I/O stress started (PID: $!) - light I/O for 10 minutes"

echo ""
echo "Stress test running for 10 minutes on $(hostname)"
echo "Tests will auto-stop after 10 minutes"
echo "To stop early: sudo pkill stress-ng; sudo pkill fio"
echo "To monitor: htop"
EOF

chmod +x /root/stress-test.sh

echo ""
echo "[4/4] Creating helper scripts..."

# Stop script
cat > /root/stop-stress.sh << 'EOF'
#!/bin/bash
echo "Stopping all stress tests..."
pkill stress-ng
pkill fio
echo "Stress tests stopped."
EOF
chmod +x /root/stop-stress.sh

# Status check script
cat > /root/check-stress.sh << 'EOF'
#!/bin/bash
echo "=== Stress Test Status on $(hostname) ==="
echo ""
if pgrep -x stress-ng > /dev/null; then
    echo "✓ CPU/Memory stress: RUNNING"
    echo "  Processes: $(pgrep -c stress-ng)"
else
    echo "✗ CPU/Memory stress: STOPPED"
fi

if pgrep -x fio > /dev/null; then
    echo "✓ Disk I/O stress: RUNNING"
else
    echo "✗ Disk I/O stress: STOPPED"
fi

echo ""
echo "Current load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory usage: $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
echo ""
EOF
chmod +x /root/check-stress.sh

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "This is a LAPTOP-FRIENDLY version with:"
echo "  - CPU at 70% (not 95%)"
echo "  - Memory 3GB of 4GB"
echo "  - Light disk I/O"
echo "  - Auto-stops after 10 minutes"
echo ""
echo "To test:"
echo "  Start test:    sudo /root/stress-test.sh"
echo "  Stop early:    sudo /root/stop-stress.sh"
echo "  Check status:  sudo /root/check-stress.sh"
echo ""
echo "Watch in VMware Workstation's VM stats to verify it works."
echo "If this works well, you're ready for the full cluster burn-in!"
echo "=================================="