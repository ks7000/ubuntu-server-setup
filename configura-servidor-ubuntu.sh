#!/bin/bash
sudo apt update
sudo apt install git

cd ~
git clone https://github.com/ks7000/ubuntu-server-setup.git
cd ubuntu-server-setup
bash setup.sh
