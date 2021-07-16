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

      "git clone --branch docker-for-integrate-with-vu https://github.com/massbitprotocol/massbitprotocol",
      "cd massbitprotocol/code-compiler",

      "sudo apt install -y python3",
      "sudo apt install -y python3-pip",
      "sudo pip3 install -U Flask",
      "sudo pip3 install -U flask-cors",

      /* Routing
      sudo cat vim /etc/nginx/sites-available/default
      
      location /code-compiler {
              add_header  X-Upstream  $upstream_addr;
              rewrite ^/code-compiler(.*) /$1 break;
              proxy_pass http://localhost:5000;
      }
      */
      # // Start our code-compiler app
      # "sudo screen -dm bash -c 'python3 app.py;'",
      

      // Setup cargo 
      "sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y",
      "sudo apt install -y cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev",
      "sudo $HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain",
      # rustup target add wasm32-unknown-unknown --toolchain stable
      // replace cargo lock

      // Setup docker
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",
      "sudo apt update",
      "apt-cache policy docker-ce",
      "sudo apt install -y docker-ce docker-compose",
      "sudo docker-compose up -d" ,

      // Install substrate api test node local
      "cd $HOME",
      "git clone https://github.com/scs/substrate-api-client-test-node",
      "cd substrate-api-client-test-node",
      "rm -f rust-toolchain",
      # "cargo run -- --dev", // Use screen for this


      # // Start chain-reader
      # "cd $HOME/massbitprotocol/chain-reader",
      # "cargo run --bin chain-reader",



      # // Todo: config /etc/nginx/sites-available to point to port 3000
      # "sudo nginx -s reload",
    ]
  }

  tags = {
    Name = format("ec2-%s", var.app_name)
  }
}
