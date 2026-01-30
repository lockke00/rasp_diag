### How to use it

1. **Copy the script**  
   ```bash
   wget https://github.com/lockke00/rasp_diag/blob/main/raspberry_diagnostic.sh
   chmod +x raspberry_diagnostic.sh
   ```

2. **Run with root privileges** (many of the files you want to read need sudo).  
   ```bash
   sudo ./raspberry_diagnostic.sh /tmp  # optional: specify output directory
   ```

3. After it finishes, look for a file like `raspberry-diagnostics-2026-01-30_14-05-12.tar.gz` in the chosen directory.

### What’s inside

| Section | Files |
|---------|-------|
| Basic system info | `basic-info.txt` |
| CPU / memory / storage stats | `system-stats.txt` |
| Disk usage & health | `df.txt`, `home-usage.txt`, optional `smart.txt` |
| Network configuration | `network.txt`, optional `ss.txt` |
| Running services & processes | `running-services.txt`, `processes.txt` |
| Boot logs | `journal.txt` (systemd) |
| Config files | `configs/`, `boot-configs/` |
| Package list | `packages.txt` |

You can now send this single archive to a support team or keep it for future reference. The script is intentionally conservative: it only reads read‑only system files, so it will work safely on any Raspberry Pi that you have access to.
