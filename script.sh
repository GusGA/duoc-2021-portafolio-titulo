#!/bin/bash

#===========================#
# Instalación de Servicios Desastentido
# Grupo Delta
#===========================#

if [ $UID -ne 0 ]; then
  echo "Necesita ser usuario root para poder ejecutar este script"
  exit 1
fi

echo -e "Creando grupo de usuarios de CloudUP"
groupadd -f cloudup
echo "------------------------------------------"
#===========================#
# Instalación servicio de Apache HTTP
#===========================#

echo -e "Instalación servicio Apache"
echo -e "Creación usuario para servicio Apache"
id -gn cloudupapache
if [ $? -ne 0 ]; then
  useradd -g cloudup cloudupapache
  if [ $? -ne 0 ]; then
    echo -e "Hubo un error creando el usuario cloudupapache"
    echo -e "Por favor ejecute 'useradd -g cloudup cloudupapache' y revise los errores"
    exit 1
  else
    echo -e "usuario cloudupapache creado exitosamente"
  fi
fi
echo ""
echo -e "Instalando servicio Apache"
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

  mkdir -p /var/www/html/
  chown -R cloudupapache /var/www/html/*
  chgrp -R cloudup /var/www/html/*

  mkdir -p /var/lock/apache2
  chown -R cloudupapache /var/lock/apache2
  chgrp -R cloudup /var/lock/apache2

  mkdir -p /var/log/apache2
  chown -R cloudupapache /var/log/apache2
  chgrp -R cloudup /var/log/apache2

  cat <<EOF >/var/www/html/index.html
<!doctype html>
<html>
  <head>
    <title>CloudUP Site</title>
  </head>
  <body>
    <h1> CloudUP Sample Web Page</h1>
    <p>Esta es template temporal para el sitio web de Cloud UP!</p>
  </body>
</html>
EOF
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
echo "------------------------------------------"
echo -e "Instalación servicio SSH"
echo -e "Creación usuario para servicio SSH"

echo -e "Ingrese contraseña para usuario cloudupssh"
read SSH_USER_PASS

id -gn cloudupssh
if [ $? -ne 0 ]; then
  useradd -g cloudup cloudupssh
  if [ $? -ne 0 ]; then
    echo -e "Hubo un error creando el usuario cloudupssh"
    echo -e "Por favor ejecute 'useradd -g cloudup cloudupssh' y revise los errores"
    exit 1
  else
    echo "cloudupssh":"$SSH_USER_PASS" | chpasswd
    if [ $? -eq 0 ]; then
      echo -e "usuario cloudupssh creado exitosamente"
    fi
  fi
fi
echo ""
echo -e "Instalando servicio SSH"
yum list installed openssh-server &>/dev/null
if [ $? -ne 0 ]; then
  echo -e "Servicio httpd no esta instalado"
  echo -e "Instalando servicio httpd"
  yum -y install openssh-server &>/dev/null
  if [ $? -ne 0 ]; then
    echo -e "Hubo un error instalando el servicio sshd"
    echo -e "Por favor ejecute 'yum install openssh-server' y revise los errores"
    exit 1
  fi
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  echo 'PermitRootLogin no' >>/etc/ssh/sshd_config
  echo 'Port 2244' >>/etc/ssh/sshd_config
  semanage port -a -t ssh_port_t -p tcp 2244

  echo "Agregando el servicio al arraque del sistema"
  chkconfig sshd on &>/dev/null
  if [ $? -eq 0 ]; then
    echo "Servicio agregado exitosamente"
  else
    echo "Hubo un problema agregando el servicio al arranque del sistema"
  fi

  firewall-cmd --permanent --add-port=2244/tcp &>/dev/null
  if [ $? -eq 0 ]; then
    echo "Puerto 2224 habilitado exitosamente"
    echo "Reiniciando firewall"
    firewall-cmd --reload &>/dev/null
    systemctl restart sshd.service
  else
    echo "Hubo un problema Habilitando el puerto"
    echo "Revise configuración del firewall e intente de nuevo"
    exit 1
  fi

else
  echo -e "Servicio SSH instalado"
  echo -e "Aplicando configuración personalizada para CloudUP"

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  echo 'PermitRootLogin no' >>/etc/ssh/sshd_config
  echo 'Port 2244' >>/etc/ssh/sshd_config

  semanage port -a -t ssh_port_t -p tcp 2244
  firewall-cmd --permanent --add-port=2244/tcp &>/dev/null
  if [ $? -eq 0 ]; then
    echo "Puerto 2224 habilitado exitosamente"
    echo "Reiniciando firewall"
    firewall-cmd --reload &>/dev/null
    systemctl restart sshd.service
  else
    echo "Hubo un problema Habilitando el puerto"
    echo "Revise configuración del firewall e intente de nuevo"
    exit 1
  fi
fi
