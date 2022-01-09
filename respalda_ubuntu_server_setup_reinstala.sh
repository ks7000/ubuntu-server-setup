#!/bin/bash
# -------------------------------------------------------------------------
# This is a free shell script under GNU GPL version 2.0 or above
# Inspired by Mr. Vivek Gite
# https://bash.cyberciti.biz/academic/ls-l-in-output-in-customized-format/
# -------------------------------------------------------------------------
clear
cd ~
carp=0
msg_salida=""
for f in $(find -name '*.bak*')
do
        if [ -d $f ]
        then
                msg_salida="[CARPETA] $f/"
                ((carp++))
        fi
        echo $msg_salida
done

echo "Total de carpetas de respaldo del proyecto, de este usuario:$carp"

((carp++))
ruta="~/ubuntu-server-setup"
if [ ! -d $ruta ]
then
        echo "Descargando de GitHub..."
        git clone https://github.com/ks7000/ubuntu-server-setup.git
else
        if [ $(mv $ruta $ruta.bak700$carp) ]
        then
                 echo "Respaldo exitoso."
        else
                 echo "¡Respaldo fallido!"
                 exit 1
        fi
fi
ls -la
