#!/bin/bash

# Verifica que sea usuario raíz
#   https://www.cyberciti.biz/tips/howto-write-shell-script-to-add-user.html
  if [ $(id -u) -eq 0 ]; then
    sudo apt update
    sudo apt install git
    cd ~
    rm -R ubuntu-server-setup/
    git clone https://github.com/ks7000/ubuntu-server-setup.git && cd ~/ubuntu-server-setup && sh ~/ubuntu-server-setup/setup.sh
  else
	echo "Solo un usuario raíz puede agregar usuarios administradores."
	exit 2
  fi
