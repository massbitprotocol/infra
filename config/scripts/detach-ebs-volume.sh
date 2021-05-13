#!/bin/bash
## device name, instance id  and volume id should be dynamic
aws ec2 detach-volume --device /dev/sdh --instance-id i-0ea6202123e992701 --volume-id vol-0824a14e6092dd9e1