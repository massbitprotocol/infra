#!/bin/bash
## Snapshot should be dynamic
## TODO: add tag here so the volume has a name
aws ec2 create-volume --volume-type gp3 --size 1000 --availability-zone ap-southeast-2c --snapshot-id snap-07683b13ff832eba3