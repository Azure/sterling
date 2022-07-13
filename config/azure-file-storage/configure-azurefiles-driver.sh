tenantId=$(cat ~/.azure/osServicePrincipal.json | jq -r .tenantId)
subscriptionId=$(cat ~/.azure/osServicePrincipal.json | jq -r .subscriptionId)
clientId=$(cat ~/.azure/osServicePrincipal.json | jq -r .clientId)
clientSecret=$(cat ~/.azure/osServicePrincipal.json | jq -r .clientSecret)
driver_version="1.19.0"

#Create the azure.json file and upload as secret
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/aro/azure.json -O /tmp/azure.json
envsubst < /tmp/azure.json > /tmp/azure.json
export AZURE_CLOUD_SECRET=`cat /tmp/azure.json | base64 | awk '{printf $0}'; echo`
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/aro/azure-cloud-provider.yaml -O /tmp/azure-cloud-provider.yaml
envsubst < /tmp/azure-cloud-provider.yaml > /tmp/azure-cloud-provider.yaml
oc apply -f /tmp/azure-cloud-provider.yaml

#sudo -E oc create secret generic azure-cloud-provider --from-literal=cloud-config=$(cat /tmp/azure.json | awk '{printf $0}'; echo) -n kube-system

#Grant access
sudo -E oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:csi-azurefile-node-sa

#Install CSI Driver
sudo -E oc create configmap azure-cred-file --from-literal=path="/etc/kubernetes/cloud.conf" -n kube-system

driver_version=$azureFilesCSIVersion
echo "Driver version " $driver_version
curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/$driver_version/deploy/install-driver.sh | bash -s $driver_version --

 #Configure Azure Files Standard
 wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/aro/azurefiles-standard.yaml -O /tmp/azurefiles-standard.yaml
 envsubst < /tmp/azurefiles-standard.yaml > /tmp/azurefiles-standard.yaml
 sudo -E oc apply -f /tmp/azurefiles-standard.yaml

#Deploy premium Storage Class
 wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/aro/azurefiles-premium.yaml -O /tmp/azurefiles-premium.yaml
 envsubst < /tmp/azurefiles-premium.yaml > /tmp/azurefiles-premium.yaml
 sudo -E oc apply -f /tmp/azurefiles-premium.yaml

#Deploy volume binder
sudo -E /tmp/OCPInstall/oc apply -f https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/aro/persistent-volume-binder.yaml