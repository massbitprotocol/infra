#!/bin/bash
sudo rsync -azvv -e 'ssh -o StrictHostKeyChecking=no -i private.pem' ubuntu@172.31.28.20:bsc /bsc

if [ $? -eq 0 ]
then
echo "Rsync is completed" | ssmtp phanthanhhuy1996@gmail.com 
else
echo "Rsync is failed" | ssmtp phanthanhhuy1996@gmail.com 
fi