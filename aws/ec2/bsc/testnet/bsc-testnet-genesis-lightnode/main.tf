# Todo: downgrade the machine a bit
# Open more port

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

  # Allow talking to our blockchain metrics
  ingress { 
    from_port   = 6060
    to_port     = 6060
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow talking to our nginx (interface of our blockchain)
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
      "sudo apt-get install -y unzip",
      "sudo apt install -y nginx",
      
      # Install BSC libraries
      "sudo git clone https://github.com/binance-chain/bsc",
      "cd bsc/",
      "sudo wget -O geth https://github.com/binance-chain/bsc/releases/download/v1.0.7/geth_linux",
      "sudo chmod +x geth",
      
      # Main Net
      "sudo wget https://github.com/binance-chain/bsc/releases/download/v1.0.7/testnet.zip",
      "sudo unzip testnet.zip",

      # Write Gensis State locally
      "sudo ./geth --datadir node init genesis.json",

      # Start light node
      "echo 'Starting geth'",
      "screen -dmS geth sudo ./geth --config ./config.toml --datadir ./node --pprofaddr 0.0.0.0 --metrics --pprof --rpc --rpccorsdomain '*' --rpcport 8545 --rpcvhosts '*' --syncmode 'light'",
      "sleep 5",

      # Start nginx to proxy pass to our blockchain RPC server
      "sudo git clone https://github.com/massbitprotocol/key",
      "sudo rm /etc/nginx/sites-available/default",
      "sudo cp key/default /etc/nginx/sites-available/default",
      "sudo nginx -s reload",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
