echo "==== AZURE CLI INSTALL ===="
#Azure CLI Install
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
sudo dnf -y install azure-cli 

#Azure CLI Login
echo "==== AZURE CLI LOGIN ===="
az login --service-principal -u $(cat ~/.azure/osServicePrincipal.json | jq -r .clientId) -p $(cat ~/.azure/osServicePrincipal.json | jq -r .clientSecret) --tenant $(cat ~/.azure/osServicePrincipal.json | jq -r .tenantId) --output none && az account set -s $(cat ~/.azure/osServicePrincipal.json | jq -r .subscriptionId) --output none

#Make mount folder and get anf IP/volume mapping
mkdir /db2data
export data_mount_ip="$(az netappfiles volume list -g $RESOURCE_GROUP --account-name $ANF_ACCOUNT_NAME --pool-name $ANF_POOL_NAME -o json | jq -r '.[] | select (.name | contains(env.ANF_POOL_NAME) and contains("data")).mountTargets[0].ipAddress')"
export data_mount_vol_name="$(az netappfiles volume list -g $RESOURCE_GROUP --account-name $ANF_ACCOUNT_NAME --pool-name $NF_POOL_NAME -o json | jq -r '.[] | select (.name | contains(env.ANF_POOL_NAME) and contains("data")).creationToken')"
fstab="$data_mount_ip:/$data_mount_vol_name /db2data nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0"
sudo su -c "echo $fstab >> /etc/fstab"
mkdir /db2log
log_mount_ip="$(az netappfiles volume list -g $RESOURCE_GROUP --account-name $ANF_ACCOUNT_NAME --pool-name $ANF_POOL_NAME -o json | jq -r '.[] | select (.name | contains(env.ANF_POOL_NAME) and contains("log")).mountTargets[0].ipAddress')"
log_mount_vol_name="$(az netappfiles volume list -g $RESOURCE_GROUP --account-name $ANF_ACCOUNT_NAME --pool-name $NF_POOL_NAME -o json | jq -r '.[] | select (.name | contains(env.ANF_POOL_NAME) and contains("log")).creationToken')"
fstab="$log_mount_ip:/$log_mount_vol_name /db2log nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0"
sudo su -c "echo $fstab >> /etc/fstab"
