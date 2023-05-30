#!/bin/bash

IP_LAN=("192.168.7.0/24" "192.168.0.0/24" "192.168.2.0/24" "192.168.4.0/24" "192.168.6.0/24")

# Install chrony
sudo apt-get update
sudo apt-get install chrony -y

# Backup the original configuration file
sudo mv /etc/chrony/chrony.conf /etc/chrony/chrony.conf.old

# Create an empty configuration file
sudo touch /etc/chrony/chrony.conf

# Set the appropriate permissions
sudo chmod 644 /etc/chrony/chrony.conf

# Restart chrony service
sudo service chrony restart

# Set the new configuration
echo 'server ntp.ubuntu.com        iburst maxsources 4
server 0.ubuntu.pool.ntp.org iburst maxsources 1
server 1.ubuntu.pool.ntp.org iburst maxsources 1
server 2.ubuntu.pool.ntp.org iburst maxsources 2

keyfile /etc/chrony/chrony.keys

driftfile /var/lib/chrony/chrony.drift

logdir /var/log/chrony

maxupdateskew 100.0

rtcsync

makestep 1 3'

# Add IP_LAN to chrony configuration
for ip in "${IP_LAN[@]}"; do
    echo "allow $ip" | sudo tee -a /etc/chrony/chrony.conf
done

sudo service chrony restart

# install mysql
apt install mariadb-server python3-pymysql -y


sudo touch /etc/mysql/mariadb.conf.d/99-openstack.cnf

sudo chmod /etc/mysql/mariadb.conf.d/99-openstack.cnf

echo '[mysqld]
bind-address = 192.168.7.252

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8' | sudo tee -a /etc/mysql/mariadb.conf.d/99-openstack.cnf

# restart mysql
service mysql restart

# amankan service database, masukan password utk root
MYSQL_ROOT_PASSWORD="admin123"

echo "NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
SERVERS IN PRODUCTION USE! PLEASE READ EACH STEP CAREFULLY!"

echo ""

echo "In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here."

echo ""

mysql_secure_installation <<EOF

$MYSQL_ROOT_PASSWORD
y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y

EOF

# Install paket rabbitmq
apt install rabbitmq-server -y

# Tambahkan user dan password openstack
rabbitmqctl add_user openstack admin123 

# set permission
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

apt install memcached python3-memcache

# edit file /etc/memcached.conf
sed -i "s/-l 127.0.0.1/-l 192.168.7.101/g" /etc/memcached.conf

# restart service
service memcached restart

# Install paket etcd
apt install etcd -y

sudo tee -a /etc/default/etcd > /dev/null << EOT
# edit file /etc/default/etcd
ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://192.168.7.101:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.7.101:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.7.101:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.7.101:2379"
EOT

# enable dan restart service etcd
systemctl enable etcd
systemctl restart etcd
