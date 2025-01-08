#!/bin/bash
#############################################
### Script de Restauración de Nextcloud   ###
### Basado en entorno OpenMediaVault V7   ###
#############################################

# Cargar configuración desde el archivo .env
if [ -f ./restore_config.env ]; then
    source ./restore_config.env
else
    echo "ERROR: No se encontró el archivo de configuración 'restore_config.env'."
    exit 1
fi

# Comprobar si el script se ejecuta como root
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: Este script debe ser ejecutado como root."
    exit 1
fi

# Descomprimir el archivo restoration_files.7z
echo "Descomprimiendo el archivo restoration_files.7z..."
7z x -p"$zipPassword" -o"$localBackupDir" "$localBackupDir/restoration_files.7z" || {
    echo "ERROR: No se pudo descomprimir el archivo restoration_files.7z.";
    exit 1;
}

# Activar modo de mantenimiento en Nextcloud
echo "Activando modo de mantenimiento en Nextcloud..."
docker exec -it nextcloud occ maintenance:mode --on || { echo "ERROR: No se pudo activar el modo de mantenimiento."; exit 1; }

# Restaurar la base de datos
echo "Restaurando la base de datos..."
gunzip < "$localBackupDir/$backupFileDB" | docker exec -i nextcloud-mariadb mysql -u"$dbUser" -p"$dbPassword" "$nextcloudDatabase" || {
    echo "ERROR: No se pudo restaurar la base de datos."; exit 1;
}

# Detener el contenedor de Nextcloud
echo "Deteniendo el contenedor de Nextcloud..."
docker-compose -f "$nextcloudComposeDir/docker-compose.yml" down || { echo "ERROR: No se pudo detener el contenedor de Nextcloud."; exit 1; }

# Restaurar las imágenes de los contenedores de Docker
echo "Restaurando imágenes de los contenedores de Docker..."
docker load -i "$localBackupDir/$backupFileNextcloudImage" || { echo "ERROR: No se pudo restaurar la imagen de Nextcloud."; exit 1; }
docker load -i "$localBackupDir/$backupFileMariaDBImage" || { echo "ERROR: No se pudo restaurar la imagen de MariaDB."; exit 1; }

# Restaurar los archivos de configuración y datos de Nextcloud
echo "Restaurando archivos de configuración y datos de Nextcloud..."
rsync -Aax --progress --delete "$localBackupDir/configDir/" "$configDir/" || { echo "ERROR: No se pudo restaurar el directorio de configuración."; exit 1; }
rsync -Aax --progress --delete "$localBackupDir/nextcloudComposeDir/" "$nextcloudComposeDir/" || { echo "ERROR: No se pudo restaurar el directorio de Docker Compose."; exit 1; }

# Modificar el archivo nextcloud.yml si es necesario
echo "Modificando archivo 'nextcloud.yml'..."
sed -i 's|/srv/dev-disk-by-uuid-[^ ]*|/ruta/actualizada|' "$nextcloudComposeDir/nextcloud.yml" || {
    echo "ERROR: No se pudo modificar el archivo nextcloud.yml."; exit 1;
}

# Iniciar los contenedores de Docker
echo "Iniciando los contenedores de Docker..."
docker-compose -f "$nextcloudComposeDir/docker-compose.yml" up -d || { echo "ERROR: No se pudieron iniciar los contenedores."; exit 1; }

# Desactivar modo de mantenimiento en Nextcloud
echo "Desactivando modo de mantenimiento en Nextcloud..."
docker exec -it nextcloud occ maintenance:mode --off || { echo "ERROR: No se pudo desactivar el modo de mantenimiento."; exit 1; }

# Confirmación de finalización
echo "Restauración completada con éxito."
