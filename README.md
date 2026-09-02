# Documentación del script cambiarDatos.sh

> Herramienta para preparar y sanear equipos o máquinas virtuales Linux.

---

## Objetivo del script

El script prepara un equipo o máquina virtual para su reutilización o clonación mediante la actualización de sus identificadores y datos principales.

Sus tareas principales son:

- Cambiar el nombre del equipo.
- Actualizar el nombre en el archivo `/etc/hosts`.
- Regenerar el identificador único de la máquina.
- Crear nuevas claves de host para el servicio SSH.
- Eliminar los historiales de comandos de los usuarios.
- Limpiar el historial de la sesión actual.
- Ofrecer el apagado de la máquina al finalizar el proceso.

Este procedimiento resulta útil para crear una máquina virtual base o reutilizar una máquina clonada evitando conservar identificadores, claves SSH e historiales del sistema original.

## Funcionamiento básico

### 1. Mostrar la ayuda

El script comprueba si se ejecutó con la opción `-h` o `--help`.

Cuando se utiliza cualquiera de estas opciones, muestra las formas disponibles para ejecutar el script y finaliza sin realizar cambios.

Uso:

    sudo chmod +x cambiarDatos.sh"
    exec sudo bash cambiarDatos.sh"
    exec sudo ./cambiarDatos.sh"
    -h, --help    Muestra esta ayuda

### 2. Comprobar los permisos

Antes de realizar cualquier operación, el script verifica que se esté ejecutando con privilegios de administrador.

Si no se ejecuta como `root` o mediante `sudo`, muestra un mensaje de error y finaliza. Esto es necesario porque modifica archivos del sistema, claves SSH, identificadores de máquina y servicios.

### 3. Cambiar el nombre del equipo

El script obtiene el nombre actual del equipo y solicita al usuario que introduzca uno nuevo.

Si se introduce un nombre válido:

- Reemplaza el nombre anterior en `/etc/hosts`.
- Establece el nuevo nombre mediante `hostnamectl`.

Si el usuario no introduce ningún valor, muestra un mensaje de error.

### 4. Regenerar el identificador de la máquina

A continuación, el script elimina el identificador actual de la máquina y vuelve a generarlo.

Para ello:

- Vacía el archivo `/etc/machine-id`.
- Elimina el identificador utilizado por D-Bus.
- Crea nuevamente el enlace correspondiente.
- Ejecuta `systemd-machine-id-setup` para generar un nuevo identificador.

Este proceso permite que el equipo tenga una identidad única después de ser reutilizado o clonado.

### 5. Regenerar las claves SSH

El script elimina las claves de host existentes del servicio SSH para evitar conservar las claves asociadas al equipo original.

Después:

- Si el sistema dispone de `dpkg-reconfigure`, utiliza esta herramienta para regenerar las claves.
- Si no está disponible, utiliza `ssh-keygen -A`.
- Reinicia el servicio SSH para aplicar los cambios.

De esta forma, el equipo obtiene nuevas claves de host SSH.

### 6. Eliminar los historiales

El script busca y elimina archivos de historial relacionados con los usuarios del sistema y con `root`.

Posteriormente:

- Crea archivos `.bash_history` vacíos cuando es necesario.
- Asigna a cada archivo su propietario correspondiente.
- Establece permisos restringidos.
- Limpia el historial almacenado en la memoria de la sesión actual.
- Guarda el historial vacío en el archivo correspondiente.

Este proceso elimina los comandos registrados anteriormente en el equipo.

### 7. Apagar la máquina

Cuando todas las tareas finalizan, el script pregunta al usuario si desea apagar la máquina virtual.

Si se responde con `s`, `S`, `si` o `SI`, el script ejecuta un apagado inmediato del equipo.

Si se introduce cualquier otra respuesta, la máquina permanece encendida.

## Consideraciones adicionales

Las operaciones relacionadas con la regeneración del identificador de máquina y de las claves SSH se ejecutan ocultando sus mensajes de salida y errores. Por este motivo, durante esas etapas no se muestran detalles técnicos en pantalla.

El script debe utilizarse con precaución, ya que elimina información del sistema que puede ser necesaria para auditorías, diagnósticos o recuperación de sesiones anteriores.