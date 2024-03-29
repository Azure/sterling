export TENANT_ID=$(cat ~/.azure/osServicePrincipal.json | jq -r .tenantId)
export SUBSCRIPTION_ID=$(cat ~/.azure/osServicePrincipal.json | jq -r .subscriptionId)
export CLIENT_ID=$(cat ~/.azure/osServicePrincipal.json | jq -r .clientId)
export CLIENT_SECRET=$(cat ~/.azure/osServicePrincipal.json | jq -r .clientSecret)
export DRIVER_VERSION="v1.18.0"
export RESOURCE_GROUP_NAME=$(cat ~/.azure/osServicePrincipal.json | jq -r .resourceGroup)


#Create the azure.json file and upload as secret
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/azure.json -O /tmp/azure.json
envsubst < /tmp/azure.json > /tmp/azure-updated.json
export AZURE_CLOUD_SECRET=`cat /tmp/azure-updated.json | base64 | awk '{printf $0}'; echo`
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/azure-cloud-provider.yaml -O /tmp/azure-cloud-provider.yaml
envsubst < /tmp/azure-cloud-provider.yaml > /tmp/azure-cloud-provider-updated.yaml
oc apply -f /tmp/azure-cloud-provider-updated.yaml

#sudo -E oc create secret generic azure-cloud-provider --from-literal=cloud-config=$(cat /tmp/azure.json | awk '{printf $0}'; echo) -n kube-system

#Grant access
sudo -E oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:csi-azurefile-node-sa

#Install CSI Driver
sudo -E oc create configmap azure-cred-file --from-literal=path="/etc/kubernetes/cloud.conf" -n kube-system

#driver_version=$azureFilesCSIVersion
echo "Driver version " $DRIVER_VERSION
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/$DRIVER_VERSION/deploy/install-driver.sh | bash -s $DRIVER_VERSION --

 #Configure Azure Files Standard
 wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/azurefiles-standard.yaml -O /tmp/azurefiles-standard.yaml
 envsubst < /tmp/azurefiles-standard.yaml > /tmp/azurefiles-standard-updated.yaml
 sudo -E oc apply -f /tmp/azurefiles-standard-updated.yaml

#Deploy premium Storage Class
 wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/azurefiles-premium.yaml -O /tmp/azurefiles-premium.yaml
 envsubst < /tmp/azurefiles-premium.yaml > /tmp/azurefiles-premium-updated.yaml
 sudo -E oc apply -f /tmp/azurefiles-premium-updated.yaml

#Deploy volume binder
sudo -E oc apply -f https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/persistent-volume-binder.yaml