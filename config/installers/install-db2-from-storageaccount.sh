#Download DB2 Installer. Environment variables set in cloudinit of VM
sudo /tmp/azcopy/azcopy copy "https://$INSTALLER_STORAGEACCOUNT_NAME.blob.core.windows.net/$INSTALLER_STORAGECONTAINER_NAME/$DB2_INSTALLER_ARCHIVE_FILENAME$INSTALLER_SAS_TOKEN" /tmp/db2.tar.gz
sudo tar -xf /tmp/db2.tar.gz -C /mnt
sudo rm /tmp/db2.tar.gz

#Get the template installer response file (nongui install)
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/db2/install.rsp -O /mnt/install.rsp
envsubst < /mnt/install.rsp > /mnt/install.rsp
sudo /mnt/server_dec/db2setup -r /mnt/install.rsp

# Change ownership of the db2 directory
sudo chown -R db2inst1:db2iadm1 /db2data/

#Configure Db2 Fault Manager (for VM restarts)
sudo /var/ibm/db2/V11.5/bin/db2fmcu -u -p /var/ibm/db2/V11.5/bin/db2fmcd
sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -U
sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -u
sudo /var/ibm/db2/V11.5/bin/db2fm -i db2inst1 -f on
/home/db2inst1/sqllib/db2profile

#Install Db2 Pacemaker
cd /mnt/server_dec/db2/linuxamd64/pcmk
sudo ./db2installPCMK -i
cd /var/ibm/db2/V11.5/install/pcmk
sudo sudo ./db2cppcmk -i

#Cleanup binaries and response file
sudo rm /mnt/install.rsp

