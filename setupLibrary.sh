#!/bin/bash

function addUserAccount() {
  # Agrega la nueva cuenta de usuario con derechos de administrador (acceso a sudo).
  # Parámetros:
  #   Nombre de usuario, variable: "username".
  #   Modo silencioso, variable: "silent_mode" (Para introducir el nombre completo del usuario, use GECOS).
  #     GECOS: https://www.cyberciti.biz/open-source/command-line-hacks/20-unix-command-line-tricks-part-i/
  #       Respaldo histórico: https://web.archive.org/web/20220108145458/https://gourmist.beligifts.com/host-https-www.cyberciti.biz/open-source/command-line-hacks/20-unix-command-line-tricks-part-i/
  
    local username=${1}
    local silent_mode=${2}

    # Fuerza a que el usuario cambie su contraseña en su primer inicio de sesión (--expire).
    # Fuerza a que el usuario solo se pueda conectar por clave SSH (--disable-password).
    #   https://www.cyberciti.biz/faq/linux-set-change-password-how-to/
    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --expire --gecos '' "${username}"
    else
        sudo adduser --disabled-password --expire "${username}"
    fi

    sudo usermod -aG sudo "${username}"
    sudo passwd -d "${username}"
}

function addSSHKey() {
  # Agrega en la máquina local la llave pública del nuevo usuario.
  # Parámetros:
  #   Nombre de usuario, variable: "username".
  #   Llave pública del usuario: "sshKey".
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

function execAsUser() {
  # Ejecutar un comando con las credenciales de otro usuario.
  # Parámetros:
  #   Nombre de usuario, variable: "username".
  #   Comando a ejecutar, variable: "exec_command"
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

function changeSSHConfig() {
  # Modifica el archivo de configuración "sshd_config".
  #   Ayuda: https://www.man7.org/linux/man-pages/man5/sshd_config.5.html
  # shellcheck disable=2116
    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
}

function setupUfw() {
  # Configura el cortafuegos (UFW) para que permita conexiones SSH con OpenSSH.
    local silent_mode=${1}
    
    # Instala el cortafuegos.
    sudo apt install ufw 
    # Añada OpenSSH a la lista de permitidos (por hacer: configurar para un puerto distinto a 22)
    sudo ufw allow OpenSSH
    # Habilita UFW.
    echo -e "¡Activación del cortafuegos UFW! \n"
    if [[ ${silent_mode} == "true" ]]; then
      yes y | sudo ufw enable
    else
      sudo ufw enable
    fi
}

function createSwap() {
  # Procede a crear la partición de intercambio de memoria (SWAP) a razón de 2 a 1 contra memoria de acceso aleatorio (RAM) instalada.
   local swapmem=$(($(getPhysicalMemory) * 2))

  #   Si la RAM excede de 8 gigabytes, instala solamente 4 GB en SWAP.
   if [ ${swapmem} -gt 8 ]; then
        swapmem=8
   fi

   sudo fallocate -l "${swapmem}G" /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
}

function mountSwap() {
  # Inicia el acceso a la partición de intercambio de memoria (SWAP), esto es llamado "montar la partición".
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

function tweakSwapSettings() {
  # Modifica la configuración de la partición de intercambio de memoria (SWAP)
    # Ayuda: https://linuxhint.com/understanding_vm_swappiness/
    local swappiness=${1}
    # Ayuda: https://bbs.archlinux.org/viewtopic.php?id=184655
    local vfs_cache_pressure=${2}

    sudo sysctl vm.swappiness="${swappiness}"
    sudo sysctl vm.vfs_cache_pressure="${vfs_cache_pressure}"
}

function saveSwapSettings() {
  # Modifica la configuración de la partición de intercambio de memoria (SWAP)
  # Utiliza el comando "sysctl" de manra indirecta, modificando su fichero de configuración.
    # Ayuda: https://linuxhint.com/understanding_vm_swappiness/
    local swappiness=${1}
    # Ayuda: https://bbs.archlinux.org/viewtopic.php?id=184655
    local vfs_cache_pressure=${2}

    echo "vm.swappiness=${swappiness}" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=${vfs_cache_pressure}" | sudo tee -a /etc/sysctl.conf
}

function setTimezone() {
  # Configura el huso horario del servidor.
  # Parámetros:
  # Huso horario, variable: "timezone".
    local timezone=${1}
    echo "${1}" | sudo tee /etc/timezone
    sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime # https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
    sudo dpkg-reconfigure -f noninteractive tzdata
}

function configureNTP() {
  # Configura el protocolo de fecha y hora (NTP).
    ubuntu_version="$(lsb_release -sr)"

    if [[ $ubuntu_version == '20.04' || $ubuntu_version == '21.10' ]]; then
        sudo systemctl restart systemd-timesyncd
    else
        sudo apt update
        sudo apt --assume-yes install ntp
        
        # force NTP to sync
        sudo service ntp stop
        sudo ntpd -gq
        sudo service ntp start
    fi
}

function getPhysicalMemory() {
  # Obtiene y muestra la memoria de acceso aleatorio (RAM) instalada en la máquina.
    local phymem
    phymem="$(free -g|awk '/^Mem:/{print $2}')"
    
    if [[ ${phymem} == '0' ]]; then
        echo 1
    else
        echo "${phymem}"
    fi
}

# Disables the sudo password prompt for a user account by editing /etc/sudoers
# Arguments:
#   Account username
function disableSudoPassword() {
  # Utilizar el comando "sudo" sin solicitud de contraseña (recuerde primero colocar acceso solamente con SSH).
    local username="${1}"

    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

function revertSudoers() {
  # Restaura los cambios realizados por la función "disableSudoPassword()"
    sudo cp /etc/sudoers.bak /etc/sudoers
    sudo rm -rf /etc/sudoers.bak
}
function actualizar(){
  # Actualizaciones de manera expedita
  alias_act="alias actualizar='sudo -- sh -c "sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && cat /var/run/reboot-required"'"
  execAsUser "${username}" "echo \"${alias_act}\" | sudo tee -a ~.bash_aliases" 
}

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings "10" "50"
}

function hasSwap() {
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Registro de eventos creado el $(date --rfc-3339='ns')"
        echo "==================="
    } >>"${filename}" 2>&1
}

function setupTimezone() {
    echo -ne "Por favor introduzca el huso horario para este servidor (de manera predeterminada 'America/Caracas'):\n" >&3
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="America/Caracas"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3
}

function instala_bat() {
  # Instala el comando bat, copia mejorada de cat. Use batcat una vez instalado.
  #   https://www.cyberciti.biz/open-source/bat-linux-command-a-cat-clone-with-written-in-rust/
    ubuntu_version="$(lsb_release -sr)"

    if [[ $ubuntu_version == '20.04' || $ubuntu_version == '21.10' ]]; then
        sudo apt install bat
        batcat -V
    else
        # Versión de Ubuntu no compatible.
        exit 1
    fi
}
