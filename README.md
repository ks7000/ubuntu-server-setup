# Guion de configuración inicial para Servidores Ubuntu

(Clonado de https://github.com/jasonheecs/ubuntu-server-setup)

Este es un guion de configuración para automatizar el inicio del aprovisionamiento de servidores Ubuntu. Hace lo siguiente
* Adiciona un nuevo usuario con derechos de usuario `root` (**sudo**).
* Agrega la _llave pública_ al nuevo usuario creado.
* Inhabilita la autenticación por contraseña en el servidor.
* Deniega el acceso directo como usuario **root** en el servidor.
* Configura **Uncomplicated Firewall** (UFW).
* (Característica deshabilitada en este repositorio) Crea un fichero de intercambio de memoria según el hardware instalado.
* Configura el huso horario del servidor (por defecto `America/Caracas`).
* Instala Network Time Protocol (NTP).

# Instalación
Debe tener Git instalado en el servidor y tener derecho a ejecutar `sudo`.

* Por medio de `curl`:
```bash
curl -O https://raw.githubusercontent.com/ks7000/ubuntu-server-setup/master/configura-servidor-ubuntu.sh && sh configura-servidor-ubuntu.sh
```

* De manera tradicional:
```bash
sudo apt update
sudo apt install git
```

Descargue una copia (*clonar*) este repositiorio a su directorio de inicio como usuario (`home`):
```bash
cd ~
git clone https://github.com/ks7000/ubuntu-server-setup.git
```

Ejecute el guion de instalación:
```bash
cd ubuntu-server-setup
bash setup.sh
```

# Parámetros de configuración
Al ejecutar el guion, será requerido el nombre del usuario para la nueva cuenta.

Luego de eso, será solicitado el adicionar una nueva llave pública (la cual debería subir de su máquina local) para la nueva cuenta. Para generar una llave ssh en su máquina local, ejecute:
```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```

Finalmente solicitará el indicar un huso horario [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) para el servidor. Si omite especificar una huso horario, será configurado automáticamente a `America/Caracas`.

# Versiones probadas
Ubuntu 14.04, Ubuntu 16.04, Ubuntu 18.04, Ubuntu 20.04, Ubuntu 21.04 y Ubuntu 21.10.

# Ejecutando pruebas
Las pruebas se realizan en un conjunto de máquinas virtuales con Vagrant. Recuerde primero activar los submódulos Git (`.gitmodules`).

Para ello ejecute los ficheros en el siguiente directorio:
`./tests/tests.sh`

