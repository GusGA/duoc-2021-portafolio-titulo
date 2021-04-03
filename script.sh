#!/bin/bash

#===========================#
# Instalación de Servicios Desastentido
# Grupo Delta
#===========================#

if [ $UID -ne 0 ]; then
  echo "Necesita ser usuario root para poder ejecutar este script"
  exit 1
fi

#===========================#
# Instalación servicio de Apache HTTP
#===========================#

yum list installed httpd &>/dev/null
if [ $? -ne 0 ]; then
  echo -e "Servicio httpd no esta instalado"
  echo -e "Instalando servicio httpd"
  yum -y install httpd &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "Hubo un error instalando el servicio httpd"
    echo -e "Por favor ejecute 'yum install httpd' y revise los errores"
    exit 1
  fi
  # Habilitando el puerto 80
  echo "Habilitando el puerto 80 en el firewall"
  firewall-cmd --zone=public --add-port=80/tcp --permanent &>/dev/null
  if [ $? -eq 0 ]; then
    echo "Puerto 80 habilitado exitosamente"
  else
    echo "Hubo un problema Habilitando el puerto"
  fi
  echo "Reiniciando firewall"
  firewall-cmd --reload &>/dev/null
  # Iniciando el servicio httpd
  systemctl start httpd.service &>/dev/null

  # Agregando el servicio al arranque del sistema
  echo "Agregando el servicio al arraque del sistema"
  systemctl enable httpd.service &>/dev/null
  if [ $? -eq 0 ]; then
    echo "Servicio agregado exitosamente"
  else
    echo "Hubo un problema agregando el servicio al arranque del sistema"
  fi
fi

# directorio="/var/www/html"
# if [ -d "$directorio/" ]; then
#   touch "$directorio/index.html"
# else
#   mkdir -p "$directorio"
#   touch "$directorio/index.html"
# fi
