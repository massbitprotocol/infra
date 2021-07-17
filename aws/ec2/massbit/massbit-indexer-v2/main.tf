#TODO: open port 443 HTTPS
#Script to add certbot
variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

variable "app_name" {
  type    = string
  default = "massbit-indexer"
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


  // Allow Https
  ingress { 
    from_port   = 443
    to_port     = 443
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
    volume_size = 100 //GB
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

      // Setup docker
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",
      "sudo apt update",
      "apt-cache policy docker-ce",
      "sudo apt install -y docker-ce docker-compose",

      // Get the nginx config
      "sudo git clone https://github.com/massbitprotocol/infra",
      "sudo rm /etc/nginx/sites-available/default",
      "sudo cp infra/aws/ec2/massbit/massbit-indexer-v2/nginx-config/default /etc/nginx/sites-available/default",

      // Get the docker-compose file to start
      "sudo git clone https://github.com/massbitprotocol/massbitprotocol",
      "cd $HOME/massbitprotocol",
      "sudo docker-compose up -d",

      "sudo nginx -s reload",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
