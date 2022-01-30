#!/bin/bash

# Verifica que sea usuario raíz
#   https://www.cyberciti.biz/tips/howto-write-shell-script-to-add-user.html
  if [ $(id -u) -eq 0 ]; then
    sudo apt update
    sudo apt --assume-yes install git
    # Instala Powerline:
    #	https://colaboratorio.net/jimmy/terminal/2019/como-instalar-powerline-en-ubuntu/
    sudo apt install fonts-powerline powerline
    echo 'if [ -f /usr/share/powerline/bindings/bash/powerline.sh ]; then source /usr/share/powerline/bindings/bash/powerline.sh; fi' | sudo tee -a ~/.bashrc
    cd ~
    rm -R ubuntu-server-setup/
    git clone https://github.com/ks7000/ubuntu-server-setup.git && bash ~/ubuntu-server-setup/setup.sh
  else
	echo "Solo un usuario raíz puede agregar usuarios administradores."
	exit 2
  fi
