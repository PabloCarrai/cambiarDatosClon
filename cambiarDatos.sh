#!/bin/bash

#	Muestra ayuda
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Uso: sudo bash cambiarDatos.sh"
    echo "Uso: sudo ./cambiarDatos.sh"
    echo "  -h, --help    Muestra esta ayuda"
    exit 0
fi

cambiar_nombre(){
   MI_EQUIPO=$(hostname)
   # 1. Solicitar el ingreso de la cadena
   read -p "Bauticemos a este equipo, nuevo nombre? : " NOMBRE_EQUIPO 
   # 2. Verificar si la variable está vacía
   if [ -z "$NOMBRE_EQUIPO" ]; then
      echo "Error: No ingresaste nada."
   else
      sed -i "s/${MI_EQUIPO}/${NOMBRE_EQUIPO}/g" /etc/hosts 
      hostnamectl set-hostname "${NOMBRE_EQUIPO}" 
   fi
   echo "Nombre del equipo cambiado $NOMBRE_EQUIPO"
}

reiniciar_id(){
   truncate -s 0 /etc/machine-id
   rm -f /var/lib/dbus/machine-id
   ln -sf /etc/machine-id /var/lib/dbus/machine-id
   systemd-machine-id-setup
} > /dev/null 2>&1

cambiar_llaves_ssh(){
   rm -f /etc/ssh/ssh_host_*_key*
   if command -v dpkg-reconfigure &> /dev/null; then
     dpkg-reconfigure openssh-server
   else
     sudo ssh-keygen -A
   fi
   sudo systemctl restart ssh
} > /dev/null 2>&1 

salir(){
   # Preguntar al usuario si desea apagar la VM
   read -p "¿Deseas apagar la máquina virtual ahora? (s/n): " respuesta
   case $respuesta in
      [sS]|[sS][iI])
         echo "Apagando el equipo..."
         shutdown -h now
         ;;
   esac
}

borrando_historial(){
   # 1. Desactivar el historial para la sesión actual del script
   export HISTFILE=/dev/null
   unset HISTFILE

   # 2. Identificar al usuario real que llamó a sudo
   USUARIO_REAL="${SUDO_USER:-$USER}"

   # 3. Vaciar y truncar todos los archivos de historial en /home y /root
   find /home /root -name ".*_history" -type f -exec truncate -s 0 {} \;
   find /home /root -name ".*_history" -type f -exec rm -f {} \;

   # 4. Limpiar los historiales específicos de bash/zsh para todos los usuarios del sistema
   for user_home in $(awk -F: '$3 >= 1000 || $1 == "root" {print $6}' /etc/passwd); do
      if [ -d "$user_home" ]; then
         rm -f "$user_home/.bash_history"
         rm -f "$user_home/.zsh_history"
         rm -f "$user_home/.ash_history"
      fi
   done

   # 5. Limpiar el historial de la terminal actual y forzar sincronización
   history -c 2>/dev/null
   history -w 2>/dev/null

   salir
}


#	Chequeo que tenga permisos de sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse con privilegios sudo." 
   exit 1
else
   echo "1) Tienes permisos para continuar"
   cambiar_nombre
   echo "2) Regenerando id..."
   reiniciar_id
   echo "3) Regenerando llaves ssh....."
   cambiar_llaves_ssh
   echo "4) Terminando el trabajo"
   borrando_historial
fi
