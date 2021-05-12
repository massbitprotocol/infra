variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

provider "aws" {
  region = "ap-southeast-2" // Sydney
}

###################################
# Environments for Massbit worker #
###################################
variable "app_name" {
  type    = string
  default = "bsc-proxy-worker-Alice"
}

variable "massbit_account" {
  type    = string
  default = "Alice"
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
  ami           = "ami-0e7fcba3aae349b0b" # Ubuntu 18.04
  instance_type = "t3.medium"

  key_name = var.key_name // Use local key 

  security_groups = [aws_security_group.security_group.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 50 //GB
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
      "sudo apt install -y ec2-instance-connect",
      "sudo apt install -y nginx",

      # Updating Massbit worker environments
      "echo '\nexport MASSBIT_ACCOUNT=${var.massbit_account}' >> ~/.profile",
      "echo '\nexport MASSBIT_PROPOSAL_ID=${var.massbit_proposal_id}' >> ~/.profile",
      "echo '\nexport MASSBIT_WSS=${var.massbit_wss}' >> ~/.profile",
      "echo '\nexport MASSBIT_HTTPS=${var.massbit_https}' >> ~/.profile",

      # Update for shell
      "export MASSBIT_ACCOUNT=${var.massbit_account}",
      "export MASSBIT_PROPOSAL_ID=${var.massbit_proposal_id}",
      "export MASSBIT_WSS=${var.massbit_wss}",
      "export MASSBIT_HTTPS=${var.massbit_https}",

      # Start nginx pointing to bsc testnet and custom "bad strategy" handling for demo
      "sudo git clone https://github.com/massbitprotocol/key",
      "sudo rm /etc/nginx/sites-available/default",
      "sudo cp key/nginx-config/bsc-testnet-proxy/default /etc/nginx/sites-available/default",
      "sudo nginx -s reload",

      # Start Provider Agent
      "sudo apt update",
      "sudo apt install -y python3-pip",
      "pip3 install scalecodec",
      "pip3 install substrate-interface",
      "pip3 install apscheduler",
      "sudo git clone -b test_demo https://github.com/massbitprotocol/massbitprotocol",
      "cd massbitprotocol",

      "printenv | grep MASSBIT",
      "python3 worker_agent/provider/provider_agent.py"
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
