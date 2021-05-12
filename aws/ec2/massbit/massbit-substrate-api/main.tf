#TODO: open port 443
#Automate the script more

variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

variable "app_name" {
  type    = string
  default = "massbit-substrate-instance"
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


  # Allow talking to our substrate
  ingress { 
    from_port   = 9933
    to_port     = 9933
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
  ami           = "ami-0e7fcba3aae349b0b" # singapore
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
      # "sudo apt install -y ec2-instance-connect",
      "sudo apt install -y nginx",
      
      # Substrate libariries
      "sudo git clone https://github.com/massbitprotocol/massbitprotocol",
      "cd massbitprotocol/substrate_massbit",

      "sudo apt update",
      "sudo apt install -y cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev",
      "sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y",
      "sudo $HOME/.cargo/bin/rustup toolchain install nightly-2020-09-27",
      "sudo $HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain nightly-2020-09-27",
      "sudo $HOME/.cargo/bin/cargo +nightly-2020-09-27 run"

      # Manually run the steps below because it's being timeout
      # "sudo apt-get update",

      # "sudo apt install make",

      # "sudo apt-get install make",
      # "cd substrate_massbit",
      # "sudo apt install -y cargo",

      # "script to build cargo",
      # "sudo ./target/release/node-template --dev --tmp --rpc-cors all",
      # "sudo screen -dmS massbit make run",
      # "sudo make run",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
