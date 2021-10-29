#!/bin/bash
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDqHy6XbGgBfB0lSlOFME/yunAtO6227BP3VoaWfxiM8HuDn0JjU+nbv+A89xntmrQL8MGwFbjy5tm+0zlIUF9DuCkwratMFcSGU/Y2xO7r8jFDO4LDFRrEucAdxfvXgyz83NjHJQG2ar092a649ZhRnuXDotEH+B8ZJNIp/Ae92FeCpAdZ4UOPLXYRtOJeXmb5Br96b5OSKQN805IQlbDeSI6DSbe4MqNzNv6fK9EOJaErHz8p7T4XCU0ihXE18PJwl/76u0KqYKWkzEBYE0Q9AiBfpcW4WUtdX9kQplaAghcHM09mq7hx1v3LvriGeJ7q5k/YvFHSfvpMZ76sdKPPU0BWXtGBvr3AGPGvMpKXqJg2ePxE8/wpr/IpMv+J1Xn540zM5kUeTK6QlCzEoVttXPGENCjCxeI7vLgN64cGe785Zb1wzi1JniFRgifPKhenlDw+XPdpYHQGgLzYrC1loYz2rR3B1Xv9DOjDEENgwSqZfdq88CeUANRL7cL7SedHXboVOFKRdSJmyggFDhODyPhBBwu0OfR4O4YpfTZb1eicRiEg3viSgKj5SaoBXQi2MaHsr/51w4u0d1bqPOIJRhR4oMOqdHQXySNkrCvPyzIGCCtts316pCqsBXh7N3Jqogj6bItUQ6rkNcws2gGvagBSR4RSC2JuxwKYs1l/yw== hughie@codelight' >> .ssh/authorized_keys
git clone https://github.com/massbitprotocol/massbitprotocol

sudo su 

DEBIAN_FRONTEND=noninteractive  apt update && \
apt install -y git curl && \
DEBIAN_FRONTEND=noninteractive curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
apt install -y cmake pkg-config libssl-dev git gcc build-essential clang libclang-dev libpq-dev \
    libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang make && \


$HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain stable && \
$HOME/.cargo/bin/rustup toolchain install nightly-2021-05-20 && \
$HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain nightly-2021-05-20 && \
$HOME/.cargo/bin/rustup install 1.53.0 && \
$HOME/.cargo/bin/rustup default 1.53.0-x86_64-unknown-linux-gnu && \
$HOME/.cargo/bin/rustup target add wasm32-unknown-unknown --toolchain 1.53.0-x86_64-unknown-linux-gnu && \
$HOME/.cargo/bin/rustup show && \

# Install NPM
apt install -y npm && \
curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
apt-get install -y nodejs && \

# Install and upgrade to python 3.8
#RUN ls
apt install -y python3 && \
apt install -y python3.8 && \
rm /usr/bin/python3 && \
ln -s python3.8 /usr/bin/python3 && \

# Install python lib
apt install -y python3-pip wget unzip && \
pip3 install -U Flask && \
pip3 install -U flask-cors && \
pip3 install -U ipfshttpclient && \
    pip3 install -U pyyaml && \
    apt-get autoremove -y && \
        apt-get clean -y 


# rm ~/.ssh/known_hosts 

# Run services in binary modes
scp target/release/manager 35.246.162.228:./
scp target/release/chain-reader 35.246.162.228:./

cp manager ./massbitprotocol/e2e-test
cp chain-reader ./massbitprotocol/e2e-test
cd massbitprotocol
make init-docker
make init-test

docker-compose -f docker-compose.min.yml up -d 

make tmux-chain-reader-binary
make tmux-indexer-v2-binary
make tmux-code-compiler


