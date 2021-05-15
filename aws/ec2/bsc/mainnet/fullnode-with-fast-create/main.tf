variable "key_name" {
  type    = string
  default = "private" // Use the existing key in AWS
}

provider "aws" {
  region = "ap-southeast-2" // Sydney
}

###################################
# Environments for Massbit worker #
###################################
variable "app_name" {
  type    = string
  default = "fullnode-with-layering-technique"
}

variable "massbit_account" {
  type    = string
  default = "Hughie"
}

variable "massbit_proposal_id" {
  type    = string
  default = "0"
}

variable "massbit_wss" {
  type    = string
  default = "wss://dev-api.massbit.io/websocket"
}

variable "massbit_https" {
  type    = string
  default = "https://dev-api.massbit.io/"
}

variable "aws_access_key_id" {
  type    = string
}

variable "aws_secret_access_key" {
  type    = string
}

###########
# Network #
###########
resource "aws_security_group" "security_group" {
  name = format("security-group-%s", var.app_name)

  # Allow SSH
  ingress { 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ingoing traffic to our nginx (RPC Server)
  ingress { 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic to anywhere.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s", var.app_name)
  }
}


##########
# Volume #
##########
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "vol-0824a14e6092dd9e1" // After detach the volume from the existing running fullnode, add that volume id here
  instance_id = aws_instance.instance.id // Mount the above volume to this instance
  skip_destroy = true // So we don't have to sync data again

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("private.pem") // An existing private key should exist inside the terraform folder so we can use remote-exec
    host        = aws_instance.instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      # Mount the volume
      "sudo lsblk -f",
      "sudo mkdir mounted-folder",
      "echo ${aws_instance.instance.id}",
      "sudo mount /dev/nvme1n1p1 mounted-folder",
      "cd mounted-folder/home/ubuntu/bsc",

      # Start BSC Node
      "sudo screen -dmS geth sudo ./geth --config ./config.toml --datadir ./node --pprofaddr 0.0.0.0 --metrics --pprof --rpc --rpccorsdomain '*' --rpcport 8545 --rpcvhosts '*' --cache=10240",

      # Start Provider Agent when mounting is completed
      # "sudo apt update",
      # "sudo apt install -y python3-pip",
      # "pip3 install scalecodec",
      # "pip3 install substrate-interface",
      # "pip3 install apscheduler",
      # "sudo git clone -b test_demo https://github.com/massbitprotocol/massbitprotocol",
      # "cd massbitprotocol",
      # "printenv | grep MASSBIT",
      # "python3 worker_agent/provider/provider_agent.py"
    ]
  }
}

############
# Instance #
############
resource "aws_instance" "instance" {
  ami           = "ami-0e7fcba3aae349b0b" // Ubuntu 18.04
  instance_type = "m5.xlarge" // This would cost 5$ a day

  key_name = var.key_name 

  security_groups = [aws_security_group.security_group.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 50 //GB
    volume_type = "gp3"
    tags = {
      Name = format("%s", var.app_name)
    }
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("private.pem") // An existing private key should exist inside the terraform folder so we can use remote-exec
    host        = aws_instance.instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ec2-instance-connect", // Upgrade to Ubuntu 20.04 so we don't have to install ec2-instance-connect manually
      "sudo apt install -y nginx", // BSC doesn't support HTTP-RPC yet, and the exisiting --rpc parameter from geth doesn't work well with CORs so we need nginx to expose the RPC server.

      # Update Massbit worker environments
      "echo '\nexport MASSBIT_ACCOUNT=${var.massbit_account}' >> ~/.profile",
      "echo '\nexport MASSBIT_PROPOSAL_ID=${var.massbit_proposal_id}' >> ~/.profile",
      "echo '\nexport MASSBIT_WSS=${var.massbit_wss}' >> ~/.profile",
      "echo '\nexport MASSBIT_HTTPS=${var.massbit_https}' >> ~/.profile",

      # Update Massbit worker environments for this shell
      "export MASSBIT_ACCOUNT=${var.massbit_account}",
      "export MASSBIT_PROPOSAL_ID=${var.massbit_proposal_id}",
      "export MASSBIT_WSS=${var.massbit_wss}",
      "export MASSBIT_HTTPS=${var.massbit_https}",

      # Start nginx pointing to bsc testnet and custom "bad strategy" handling for demo
      "sudo git clone https://github.com/massbitprotocol/infra",
      "sudo rm /etc/nginx/sites-available/default",
      "sudo cp infra/config/nginx-config/bsc-mainnet/default /etc/nginx/sites-available/default",
      "sudo nginx -s reload",

      # Config AWS CLI
      "sudo apt update",
      "sudo apt install -y awscli",
      "aws configure set aws_access_key_id ${var.aws_access_key_id} ",
      "aws configure set aws_secret_access_key ${var.aws_secret_access_key} ",
      "aws configure set default.region ap-southeast-2",

      # After volume is attached, another shell will mount the volume then start the BSC Fullnode and agent
    ]
  }

  tags = {
    Name = format("%s", var.app_name)
  }
}
