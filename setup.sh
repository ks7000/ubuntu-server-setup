#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    # shellcheck source=./setupLibrary.sh
    source "${current_dir}/setupLibrary.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function main() {
    # El comando trap proporciona la herramienta para capturar una interrupción (señal) y luego limpiarla dentro del guion.
    # https://bash.cyberciti.biz/guide/How_to_clear_trap
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    # Utilidad principal de este proyecto.
    read -rp "Por favor introduzca el nombre de usuario para la nueva cuenta:" username

    # Agrega la cuenta:
        # Verifica si el usuario existe:
        existe_u=$(getent passwd | cut -d: -f1 | grep "${username}")
        if [ "${existe_u}" = "${username}" ];
        then 
            addUserAccount "${username}"
        else
            echo "El usuario ya existe."
        fi
    read -rp $'Por favor introduzca la LLAVE PÚBLICA para el nuevo usuario:\n' sshKey
    echo 'Inicio del trabajo...'
    logTimestamp "${output_file}"

    exec 3>&1 >>"${output_file}" 2>&1
    disableSudoPassword "${username}"
    
    # Agrega la llave pública al usuario:
    addSSHKey "${username}" "${sshKey}"
    
    # Cambia la configuración SSH:
    changeSSHConfig
    
    # Configura el cortafuegos:
    setupUfw true

    # (Deshabilitado) Si no existe la partición de intercambio, la configura:
    #if ! hasSwap; then
    #    setupSwap
    #fi

    # Configura el huso horario:
    setupTimezone

    # https://es.wikipedia.org/wiki/Network_Time_Protocol
    echo "Instala el protocolo de hora de red (NTP)... " >&3
    
    # Actualiza los repositorios con apt.
    actualizarRepo
    # Configura el NTP
    configureNTP
    
    # Instala bat
    instala_bat

    # Renicia el servicio SSH (¿Por qué?)
    sudo service ssh restart

    # Limpieza de variables:
    cleanup

    echo "¡Trabajo realizado! El archivo de registro está en ${output_file}" >&3
}

main
