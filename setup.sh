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
    # Utilidad principal de este proyecto.
    read -rp "Por favor introduzca el nombre de usuario para la nueva cuenta:" username

    # El comando trap proporciona la herramienta para capturar una interrupción (señal) y luego limpiarla dentro del guion.
    # https://bash.cyberciti.biz/guide/How_to_clear_trap
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    # Agrega la cuenta:
    addUserAccount "${username}"

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
    
    # Configura el NTP
    configureNTP

    # Renicia el servicio SSH (¿Por qué?)
    sudo service ssh restart

    # Limpieza de variables:
    cleanup

    echo "¡Trabajo realizado! El archivo de registro está en ${output_file}" >&3
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

main
