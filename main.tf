variable "key_name" {
  type    = string
  default = "private" // Private key name should be private.pem
}

######################
# Use Local Key Pair #
######################
resource "aws_key_pair" "local-key" {
  key_name   = var.key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCobv/3BoBV9zFKlBhS98tGCCfLYBFHSeCDQbmv53akhJN1jyFjmNbKPWGLxytvtNizW7xck8I3zT3JDptQeGkUOx+4iEHQUMuSaI1Ee7MQdUtZ4xwt8Hlpc6EiZIKWL8ClOguwzCYmNkocGlXiuuOJag/yRG6trok6CYFUf2WlB+p1lReWKLToCA5IKabur/iWQhuZA0eZHqIFztyZ3656WGYlq9/LkUqrDP/PKc4PtGVUjAkOlKyM9KWSMW077R2Ku4Oc4FhNnZIrDWOj3cW/L8lawWxvsQ5pvpk/8LeW+asBoZvjvCPkshT5aw7Oi4znudM6ZkbuBxrvZswv3F8T6yeJteaeV1A5iMjCaUMKsoKtckVGOfKjVGB8DqtkQugouGia0j1Z94hy95QTgN1TiE0duIGqO5y3ywrbyk9dIJVobumHJf+tSaA87xOKVxC+j6NDUabUde3HakC4MlUc1GL3dRP/zUCGgpm6M95TAlX4gcIYfbriJ7JA3chFD32s+yfpCRILUaFn10MjOscD5qvchYdf9hd9jVyQRSkstYeTq8Z8CS5jgOVJ0FAa+EBR8cz0f8Csun/9NpM5sQbjTeRRnT3LcwMGFrKRyFKvoy/ln8f4TdkCEaAuDpvMROz/IeWnAuCR3Rq6NcPypwQ1hX/w7Cl2DsvJCrW/Qr2cmQ=="
}

provider "aws" {
  region = "ap-southeast-2" // Sydney
}

###########
# Network #
###########
resource "aws_security_group" "sg" {
  name = "sg"

  # Allow SSH
  ingress { 
    from_port   = 22
    to_port     = 22
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

  security_groups = [aws_security_group.sg.name]

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

      # Install BSC libraries
      "sudo git clone https://github.com/binance-chain/bsc",
      "cd bsc/",
      "sudo wget -O geth https://github.com/binance-chain/bsc/releases/download/v1.0.7/geth_linux",
      "sudo chmod +x geth",
      
      # Main Net
      "sudo wget https://github.com/binance-chain/bsc/releases/download/v1.0.7/mainnet.zip",
      "sudo unzip mainnet.zip",

      # Write Gensis State locally
      "sudo ./geth --datadir node init genesis.json",

      # Start fullnode
      "sudo ./geth --config ./config.toml --datadir ./node --pprofaddr 0.0.0.0 --metrics --pprof",
    ]
  }

  tags = {
    Name = "ec2-bsc-mainnet-instance"
  }
}
