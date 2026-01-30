#!/bin/bash

# Raspberry Pi Diagnostic Information Script
# Collects system diagnostics and saves to a file

# Output file with timestamp
OUTPUT_FILE="rpi_diagnostics_$(date +%Y%m%d_%H%M%S).txt"

# Function to print section headers
print_header() {
    echo "========================================" >> "$OUTPUT_FILE"
    echo "$1" >> "$OUTPUT_FILE"
    echo "========================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Start diagnostic collection
echo "Raspberry Pi Diagnostic Report" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# System Information
print_header "SYSTEM INFORMATION"
uname -a >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Raspberry Pi Model
print_header "RASPBERRY PI MODEL"
if [ -f /proc/device-tree/model ]; then
    cat /proc/device-tree/model >> "$OUTPUT_FILE" 2>&1
    echo "" >> "$OUTPUT_FILE"
fi
cat /proc/cpuinfo | grep -E "Model|Hardware|Revision|Serial" >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# OS Version
print_header "OPERATING SYSTEM"
if [ -f /etc/os-release ]; then
    cat /etc/os-release >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Kernel Version
print_header "KERNEL VERSION"
uname -r >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# CPU Information
print_header "CPU INFORMATION"
lscpu >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"
echo "CPU Frequency:" >> "$OUTPUT_FILE"
if command -v vcgencmd &> /dev/null; then
    vcgencmd measure_clock arm >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Temperature
print_header "TEMPERATURE"
if command -v vcgencmd &> /dev/null; then
    echo "CPU Temperature:" >> "$OUTPUT_FILE"
    vcgencmd measure_temp >> "$OUTPUT_FILE" 2>&1
fi
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    echo "Thermal Zone: $(($(cat /sys/class/thermal/thermal_zone0/temp)/1000))°C" >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Memory Information
print_header "MEMORY INFORMATION"
free -h >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"
if command -v vcgencmd &> /dev/null; then
    echo "GPU Memory:" >> "$OUTPUT_FILE"
    vcgencmd get_mem arm >> "$OUTPUT_FILE" 2>&1
    vcgencmd get_mem gpu >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Disk Usage
print_header "DISK USAGE"
df -h >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# SD Card Information
print_header "SD CARD INFORMATION"
if [ -b /dev/mmcblk0 ]; then
    echo "SD Card Device: /dev/mmcblk0" >> "$OUTPUT_FILE"
    sudo fdisk -l /dev/mmcblk0 >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Uptime
print_header "UPTIME"
uptime >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Load Average
print_header "LOAD AVERAGE"
cat /proc/loadavg >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Running Processes
print_header "TOP PROCESSES (by CPU)"
ps aux --sort=-%cpu | head -11 >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

print_header "TOP PROCESSES (by Memory)"
ps aux --sort=-%mem | head -11 >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Network Information
print_header "NETWORK INTERFACES"
ip addr show >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

print_header "NETWORK CONNECTIONS"
ss -tuln >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# USB Devices
print_header "USB DEVICES"
lsusb >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# GPIO Status (if available)
print_header "GPIO STATUS"
if command -v gpio &> /dev/null; then
    gpio readall >> "$OUTPUT_FILE" 2>&1
else
    echo "gpio command not available (install wiringpi)" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Voltage and Power
print_header "VOLTAGE AND POWER"
if command -v vcgencmd &> /dev/null; then
    echo "Core Voltage:" >> "$OUTPUT_FILE"
    vcgencmd measure_volts core >> "$OUTPUT_FILE" 2>&1
    echo "" >> "$OUTPUT_FILE"
    echo "Throttling Status:" >> "$OUTPUT_FILE"
    vcgencmd get_throttled >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# Boot Configuration
print_header "BOOT CONFIGURATION"
if [ -f /boot/config.txt ]; then
    grep -v "^#\|^$" /boot/config.txt >> "$OUTPUT_FILE" 2>&1
elif [ -f /boot/firmware/config.txt ]; then
    grep -v "^#\|^$" /boot/firmware/config.txt >> "$OUTPUT_FILE" 2>&1
fi
echo "" >> "$OUTPUT_FILE"

# I2C Devices
print_header "I2C DEVICES"
if command -v i2cdetect &> /dev/null; then
    for i in 0 1; do
        echo "Bus $i:" >> "$OUTPUT_FILE"
        sudo i2cdetect -y $i >> "$OUTPUT_FILE" 2>&1
        echo "" >> "$OUTPUT_FILE"
    done
else
    echo "i2c-tools not installed" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# System Logs (last 50 lines)
print_header "RECENT SYSTEM LOGS"
sudo journalctl -n 50 --no-pager >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# dmesg errors
print_header "KERNEL ERRORS (dmesg)"
sudo dmesg | grep -i "error\|warning\|fail" | tail -20 >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Installed Packages (Raspberry Pi specific)
print_header "RASPBERRY PI PACKAGES"
dpkg -l | grep -i "raspberrypi\|raspi" >> "$OUTPUT_FILE" 2>&1
echo "" >> "$OUTPUT_FILE"

# Summary
print_header "DIAGNOSTIC COLLECTION COMPLETE"
echo "Report saved to: $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"

# Print completion message
echo "Diagnostic information collected successfully!"
echo "Output saved to: $OUTPUT_FILE"
echo ""
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
