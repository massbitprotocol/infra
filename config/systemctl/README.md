# Useful commands

## Gateway
```
cd /etc/systemd/system
journalctl -u update-worker-ip.service

systemctl reset-failed update-worker-ip.service
systemctl start update-worker-ip.timer
systemctl stop update-worker-ip.service
systemctl daemon-reload
```

## bsc-fullnode
```
cd /etc/systemd/system
journalctl -u geth.service
systemctl start geth.service
systemctl stop geth.service
systemctl daemon-reload
```