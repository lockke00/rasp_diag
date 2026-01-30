## What the script collects:

- **Hardware Info**: Pi model, CPU details, revision, serial number
- **System Status**: OS version, kernel, uptime, load average
- **Performance Metrics**: CPU temperature, voltage, throttling status, CPU frequency
- **Memory**: RAM usage, GPU memory allocation
- **Storage**: Disk usage, SD card information
- **Network**: Interfaces, active connections
- **Processes**: Top CPU and memory consumers
- **Peripherals**: USB devices, GPIO status, I2C devices
- **Configuration**: Boot config settings
- **Logs**: Recent system logs and kernel errors
- **Power**: Voltage levels and throttling warnings

## To use it:

```bash
# Make executable (if needed)
chmod +x rpi_diagnostics.sh

# Run the script
./rpi_diagnostics.sh

# Or with sudo for complete information
sudo ./rpi_diagnostics.sh
```

The script will create a file named `rpi_diagnostics_YYYYMMDD_HHMMSS.txt` with all the collected information. Some commands (like I2C detection and full disk info) work best when run with sudo, but the script will still collect most information without it.
