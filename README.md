# Script de Restauración de Nextcloud con Rclone y Borg

## Descripción

Este script permite restaurar una instancia de Nextcloud respaldada previamente en un entorno OpenMediaVault V7. Se encarga de descomprimir los archivos sensibles, restaurar la base de datos, sincronizar los archivos de configuración y datos, y reiniciar los contenedores de Docker.

## Requisitos

- **Sistema operativo Linux** con acceso de root.
- **Docker** para manejar los contenedores de Nextcloud y MariaDB.
- **7z** para la descompresión de archivos.
- **Rclone** configurado en caso de restaurar archivos desde un almacenamiento remoto.
- **BorgBackup** para la extracción de respaldos si se usó Borg durante el proceso de copia de seguridad.

## Instalación y Configuración

### 1. Preparar el Archivo de Configuración `.env`

Crea el archivo `restore_config.env` en la misma ubicación del script y define las siguientes variables:

```bash
# Configuración de la base de datos
export dbUser='root'                              # Usuario de la base de datos
export dbPassword='tu_contraseña_db'              # Contraseña de la base de datos
export nextcloudDatabase='nextcloud_database'     # Nombre de la base de datos

# Configuración de rutas de backup y archivos comprimidos
export zipPassword='tu_contraseña_7z'              # Contraseña del archivo comprimido
export localBackupDir='/ruta/al/backup/temp'      # Directorio temporal donde se encuentran los respaldos
export backupFileDB='nombre_del_respaldo-nextcloud-db.sql.gz'          # Nombre del archivo de respaldo de la base de datos
export backupFileNextcloudImage='nombre_del_respaldo-nextcloud-image.tar'  # Nombre del archivo de la imagen de Nextcloud
export backupFileMariaDBImage='nombre_del_respaldo-mariadb-image.tar'      # Nombre del archivo de la imagen de MariaDB

# Directorios y servicios de Nextcloud
export configDir='/ruta/config/nextcloud/'               # Ruta al directorio de configuración de Nextcloud
export nextcloudComposeDir='/ruta/compose/nextcloud/'    # Ruta al directorio de configuración de Docker Compose
```

### 2. Verificar Permisos

Asegúrate de que el script tenga permisos de ejecución:

```bash
chmod +x restore_nextcloud.sh
```

## Uso del Script

### Ejecución Manual

Para iniciar el proceso de restauración, ejecuta el script:

```bash
sudo ./restore_nextcloud.sh
```

El script realizará las siguientes acciones:

1. **Descompresión** del archivo comprimido `restoration_files.7z` utilizando la contraseña configurada.
2. **Activación del modo de mantenimiento** en Nextcloud.
3. **Restauración de la base de datos** mediante un volcado SQL descomprimido.
4. **Detención de los contenedores de Nextcloud y MariaDB**.
5. **Restauración de las imágenes de Docker** de Nextcloud y MariaDB.
6. **Sincronización de los archivos** de configuración y datos utilizando `rsync`.
7. **Modificación del archivo `nextcloud.yml`** si es necesario para ajustar las rutas.
8. **Reinicio de los contenedores de Docker**.
9. **Desactivación del modo de mantenimiento** en Nextcloud.

## Notas Importantes

- Asegúrate de que los respaldos estén completos y disponibles antes de iniciar el proceso de restauración.
- La variable `zipPassword` debe contener la contraseña correcta para descomprimir los archivos sensibles.
- Si se han cambiado las rutas en el sistema, actualiza el archivo `nextcloud.yml` manualmente o verifica que el script lo haya hecho correctamente.

## Restauración desde Rclone (Opcional)

Si necesitas restaurar los archivos desde un almacenamiento remoto configurado en Rclone, ejecuta el siguiente comando antes de iniciar el script:

```bash
rclone copy "nombre_remoto:/ruta_de_respaldo" "${localBackupDir}" --progress
```

Esto copiará los respaldos desde el almacenamiento remoto al directorio temporal configurado en `localBackupDir`. Posteriormente, ejecuta el script de restauración como se indicó anteriormente.

## Contribuciones

Este script ha sido desarrollado para entornos específicos de Nextcloud en OpenMediaVault V7, pero puede adaptarse a otras configuraciones similares. Si deseas contribuir o proponer mejoras, no dudes en hacerlo.

## Licencia

Este proyecto está disponible bajo la licencia MIT.
