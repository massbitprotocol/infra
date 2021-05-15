#!/bin/bash
## Snapshot should be dynamic
## TODO: add tag here so the volume has a name
# This script should be added in the root node and re-run after every 2 hours
# volume-bsc-data-seed-node
aws ec2 create-snapshot --volume-id vol-027bd6f9547af7041 --description "bsc-mainnet-13-5-2021-5PM"