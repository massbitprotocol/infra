# Useful commands
```
cd /etc/systemd/system
journalctl -u update-worker-ip.service

systemctl reset-failed update-worker-ip.service
systemctl start update-worker-ip.timer
systemctl stop update-worker-ip.timer
systemctl stop update-worker-ip.service
systemctl daemon-reload
```
