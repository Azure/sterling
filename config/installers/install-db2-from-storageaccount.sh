#Download DB2 Installer. Environment variables set in cloudinit of VM
sudo /tmp/azcopy/azcopy copy "https://$INSTALLER_STORAGEACCOUNT_NAME.blob.core.windows.net/$INSTALLER_STORAGECONTAINER_NAME/$DB2_INSTALLER_ARCHIVE_FILENAME?$INSTALLER_SAS_TOKEN" /tmp/db2.tar.gz
sudo tar -xf /tmp/db2.tar.gz -C /db2data
sudo rm /tmp/db2.tar.gz

#Get the template installer response file (nongui install)
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/db2/install.rsp -O /tmp/install.rsp
envsubst < /tmp/install.rsp > /tmp/install_configured.rsp
sudo /db2data/server_dec/db2setup -r /tmp/install_configured.rsp

# Change ownership of the db2 directory
sudo chown -R db2inst1:db2iadm1 /db2data/

#Configure autostart
sudo -i -u db2inst1 bash << EOF
cd ~/sqllib/bin
./db2iauto -on db2inst1
EOF

#Create new database
sudo -i -u db2inst1 bash << EOF
cd /home/db2inst1/sqllib
./db2profile
echo $DB2_DATABASE_NAME
db2 create database $DB2_DATABASE_NAME on /db2data
db2 connect to $DB2_DATABASE_NAME
db2 create schema $DB2_SCHEMA_NAME
EOF

#Configure Db2 Fault Manager (for VM restarts)
/var/ibm/db2/bin/db2fmcu -u -p /var/ibm/db2/bin/db2fmcd
/var/ibm/db2/bin/db2fm -i db2inst1 -U
/var/ibm/db2/bin/db2fm -i db2inst1 -u
/var/ibm/db2/bin/db2fm -i db2inst1 -f on
/home/db2inst1/sqllib/db2profile

#Install Db2 Pacemaker
cd /db2data/server_dec/db2/linuxamd64/pcmk
sudo ./db2installPCMK -i
cd /var/ibm/db2/install/pcmk
sudo ./db2cppcmk -i

#Cleanup binaries and response file
sudo rm /tmp/*.rsp
sudo rm -R /db2data/server_dec

#Update Firewall Rules
firewall-offline-cmd --zone=public --add-port=25000/tcp
firewall-offline-cmd --zone=public --add-port=25010/tcp
firewall-offline-cmd --zone=public --add-port=3121/tcp
firewall-offline-cmd --zone=public --add-port=5403/tcp
firewall-offline-cmd --zone=public --add-port=5404/udp
firewall-offline-cmd --zone=public --add-port=5405/udp
firewall-offline-cmd --zone=public --add-port=62500/tcp
systemctl enable firewalld
systemctl start firewalld