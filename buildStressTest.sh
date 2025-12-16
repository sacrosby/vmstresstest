#!/bin/bash
# VMware Cluster Burn-in Configuration Script
# Configures Ubuntu 24.04 VM for hardware stress testing

set -e

echo "=================================="
echo "VMware Cluster Burn-in Setup"
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
echo "[3/4] Creating burn-in stress script..."
cat > /root/stress-all.sh << 'EOF'
#!/bin/bash
# Burn-in stress test - CPU, Memory, and Disk
echo "Starting burn-in stress test on $(hostname) at $(date)"

# CPU: use all cores at 95%
stress-ng --cpu $(nproc) --cpu-load 95 &
echo "CPU stress started (PID: $!)"

# Memory: use 200GB (50GB x 4 workers)
stress-ng --vm 4 --vm-bytes 50G &
echo "Memory stress started (PID: $!)"

# Disk: continuous random I/O
fio --name=burnin --directory=/mnt/iotest --size=50G \
    --rw=randrw --bs=4k --direct=1 --numjobs=8 \
    --ioengine=libaio --iodepth=32 --loops=999 &
echo "Disk I/O stress started (PID: $!)"

echo ""
echo "Burn-in stress test running on $(hostname)"
echo "To stop: sudo pkill stress-ng; sudo pkill fio"
echo "To monitor: htop or watch -n 2 iostat -x"
EOF

chmod +x /root/stress-all.sh

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
    echo "✓ CPU stress: RUNNING"
    echo "  Processes: $(pgrep -c stress-ng)"
else
    echo "✗ CPU stress: STOPPED"
fi

if pgrep -x fio > /dev/null; then
    echo "✓ Disk I/O stress: RUNNING"
else
    echo "✗ Disk I/O stress: STOPPED"
fi

echo ""
echo "Current load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""
EOF
chmod +x /root/check-stress.sh

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Shutdown this VM"
echo "2. In vCenter: Edit VM settings to 24 vCPU / 240GB RAM"
echo "3. Clone this VM for as many hosts as you have in your cluser (assuming DRS is enabled)
echo "4. Power on all VMs"
echo "5. SSH to each VM and run: sudo /root/stress-all.sh"
echo ""
echo "Management commands:"
echo "  Start stress:  sudo /root/stress-all.sh"
echo "  Stop stress:   sudo /root/stop-stress.sh"
echo "  Check status:  sudo /root/check-stress.sh"
echo ""
echo "Monitor in vCenter for 7 days, watch for hardware alarms."
echo "=================================="