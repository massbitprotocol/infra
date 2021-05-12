# Create a Fully BSC Mainnet from existing EBS Snapshot

## Note
- If the snapshot is created 10 hours ago, the eth_syncing currentBlock will be behind 10 hours.
- I think the state trie won't be re-calculated (State trie usually takes the most time)

## Usage
```
terraform init
terraform apply -auto-approve
```

## Requirements
- AWS Credentials
- Terraform
- Private Key
- Existing snapshot ID from a synced and running fullnode