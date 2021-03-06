#TODO: open port 443 HTTPS
#Script to add certbot
variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

variable "app_name" {
  type    = string
  default = "nfttify-backend"
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

  // Allow Proxy Interface
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
  instance_type = "t3.small"

  key_name = var.key_name // Use local key 

  security_groups = [aws_security_group.security_group.name]

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = 20 //GB
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

      "sudo apt install -y npm",
      "sudo npm install --global yarn",

      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",

      // Todo: add user name password
      "git clone https://github.com/NhutVu23/nfttify",
      
      "cd nfttify",
      "yarn install",

      // Todo: Reconfig package json from "set" to "export" to get NODE_ENV
      "sudo screen -dm bash -c 'export NODE_ENV=development; yarn run start:dev;'",
      
      // Todo: config /etc/nginx/sites-available to point to port 3000
      "sudo nginx -s reload",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
