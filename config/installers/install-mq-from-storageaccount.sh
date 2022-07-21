#Download MQ Installer. Environment variables set in cloudinit of VM
echo $INSTALLER_SAS_TOKEN
sudo /tmp/azcopy/azcopy copy  "https://$INSTALLER_STORAGEACCOUNT_NAME.blob.core.windows.net/$INSTALLER_STORAGECONTAINER_NAME/$MQ_INSTALLER_ARCHIVE_FILENAME?$INSTALLER_SAS_TOKEN" /tmp/mq.tar.gz
sudo tar -xf /tmp/mq.tar.gz -C /mnt
sudo rm /tmp/mq.tar.gz
cd /mnt/MQServer
./mqlicense.sh -accept
sudo rpm -ivh MQSeriesGSKit-* MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm
sudo rpm -Uvh MQSeriesJava-*.rpm
sudo sed -i 's+home/user/JNDI-Directory+MQHA/jndi+g' /opt/mqm/java/bin/JMSAdmin.config

#Adjust user settings for mqm
sudo usermod -G azureuser mqm
sudo chown -R mqm:mqm /MQHA
sudo chmod -R ug+rwx /MQHA
echo "mqm       soft  nofile     10240" >> /etc/security/limits.conf 
echo "mqm       hard  nofile     10240" >> /etc/security/limits.conf 

#Set firewall port
firewall-offline-cmd --zone=public --add-port=6566/tcp
systemctl enable firewalld
systemctl start firewalld