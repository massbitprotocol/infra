# TODO : need to add more port
# Need to rewrite as systemctl service file
# Use 5xzn 6xlarge instead of 2xlarge
# Need test geth works after rsync
# Update geth version

variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

variable "app_name" {
  type    = string
}

provider "aws" {
  region = "ap-southeast-2" // Sydney
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

  # Allow talking to our blockchain
  ingress { 
    from_port   = 6060
    to_port     = 6060
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
}

############
# Instance #
############
resource "aws_instance" "instance" {
  ami           = "ami-09b1eb4f62e1813d0" # singapore
  instance_type = "m5.2xlarge"

  key_name = var.key_name // Use local key 

  security_groups = [aws_security_group.security_group.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 1000 // 1TB
    volume_type = "gp2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("private.pem")
    host        = aws_instance.instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y unzip ec2-instance-connect",
      "sudo apt-get install -y zip unzip",

      # Install BSC libraries
      "sudo git clone https://github.com/binance-chain/bsc",
      "cd bsc/",
      "sudo wget -O geth https://github.com/binance-chain/bsc/releases/download/v1.0.7/geth_linux",
      "sudo chmod +x geth",

      # Main Net
      "sudo wget https://github.com/binance-chain/bsc/releases/download/v1.0.7/mainnet.zip",
      "sudo unzip mainnet.zip",

      # Sync data externally from latest node (bsc-mainnet-a) 
      # "screen -dmS external-rsync sudo rsync -azvv -e 'ssh -o StrictHostKeyChecking=no -i private.pem' ubuntu@13.211.177.53:bsc/node /node",
      # "sleep 5",

      # Sync data internally from latest node (bsc-mainnet-a)
      "screen -dmS internal-rsync sudo rsync -azvv -e 'ssh -o StrictHostKeyChecking=no -i private.pem' ubuntu@172.31.28.20:bsc/node /node",
      "sleep 5",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
