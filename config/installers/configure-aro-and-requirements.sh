#Required Software Pacakges
sudo dnf -y install jq

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

#Install kubectl
echo "==== KUBECTL INSTALL ===="
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo dnf install -y kubectl

#Openshift CLI Install
echo "==== OC INSTALL ===="
mkdir /tmp/OCPInstall
wget -nv "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz" -O /tmp/OCPInstall/openshift-client-linux.tar.gz
tar xvf /tmp/OCPInstall/openshift-client-linux.tar.gz -C /tmp/OCPInstall
sudo cp /tmp/OCPInstall/oc /usr/bin

#Helm install
#echo "==== HELM INSTALL ===="
#curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
#chmod 700 /tmp/get_helm.sh
#/tmp/get_helm.sh

#OC Login
echo "==== ATTEMPTING CLUSTER CLI LOGIN ===="
apiServer=$(az aro show -g $(cat ~/.azure/osServicePrincipal.json | jq -r .resourceGroup) -n $ARO_CLUSTER --query apiserverProfile.url -o tsv | sed -e 's#^https://##; s#/##' )
adminpassword=$(az aro list-credentials --name $ARO_CLUSTER --resource-group $(cat ~/.azure/osServicePrincipal.json | jq -r .resourceGroup) --query kubeadminPassword -o tsv)
oc login $apiServer -u kubeadmin -p $adminpassword

#Create Required Namespace
oc create namespace $OMS_NAMESPACE

#Install & Configure Azure Files CSI Drivers and Storage Classes
echo "==== START AZURE FILES CONFIGURATION ===="
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/azure-file-storage/configure-azurefiles-driver.sh -O /tmp/configure-azurefiles-driver.sh
chmod u+x /tmp/configure-azurefiles-driver.sh
/tmp/configure-azurefiles-driver.sh

#Configure IBM Operator Catalog
echo "==== OPERATOR INSTALL ===="
oc create namespace openshift-marketplace
wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/operators/ibm-integration-operatorgroup.yaml -O /tmp/ibm-integration-operatorgroup.yaml
envsubst < /tmp/ibm-integration-operatorgroup.yaml > /tmp/ibm-integration-operatorgroup-updated.yaml
oc apply -f /tmp/ibm-integration-operatorgroup-updated.yaml

#Install OMS Opeartor
export OMS_VERSION=$WHICH_OMS

if [ "$WHICH_OMS" == *"-pro-"* ]
then
  export OPERATOR_NAME="ibm-oms-pro"
  export OPERATOR_CSV="ibm-oms-pro.v1.0.0"
else
  export OPERATOR_NAME="ibm-oms-ent"
  export OPERATOR_CSV="ibm-oms-ent.v1.0.0"
fi

echo "Installing OMS Operator..."
echo "Name: $OPERATOR_NAME"
echo "Operator CSV: $OPERATOR_CSV"

wget -nv https://raw.githubusercontent.com/Azure/sterling/$BRANCH_NAME/config/operators/install-oms-operator.yaml -O /tmp/install-oms-operator.yaml
envsubst < /tmp/install-oms-operator.yaml > /tmp/install-oms-operator-updated.yaml
oc apply -f /tmp/install-oms-operator-updated.yaml

#Optional Install Portion
if [ "$INSTALL_DB2_CONTAINER" == "Y" ] || [ "$INSTALL_DB2_CONTAINER" == "y" ]
then
  echo "Installing DB2 Container in namespace $OMS_NAMESPACE..."
  oc create serviceaccount mysvcacct -n $OMS_NAMESPACE
  oc adm policy add-scc-to-user privileged system:serviceaccount:$OMS_NAMESPACE:db2svcacct
  oc adm policy add-scc-to-user anyuid -z db2svcacct -n $OMS_NAMESPACE

  wget https://raw.githubusercontent.com/Azure/sterling/anfurgiu/init/config/docker/db2/db2-pvc.yaml -O /tmp/db2-pvc.yaml
  wget https://raw.githubusercontent.com/Azure/sterling/anfurgiu/init/config/docker/db2/db2.yaml -O /tmp/db2.yaml
  envsubst < /tmp/db2-pvc.yaml > /tmp/db2-pvc-updated.yaml
  envsubst < /tmp/db2.yaml > /tmp/db2-updated.yaml
  
  oc apply -f /tmp/db2-pvc-updated.yaml
  oc apply -f /tmp/db2-updated.yaml

  oc set sa deployment db2 -n $OMS_NAMESPACE db2svcacct
fi
if [ "$INSTALL_MQ_CONTAINER" == "Y" ] || [ "$INSTALL_MQ_CONTAINER" == "y" ]
then
  echo "Installing ActiveMQ Container in namespace $OMS_NAMESPACE..."
  wget https://raw.githubusercontent.com/Azure/sterling/anfurgiu/init/config/docker/activemq/activemq.yaml -O /tmp/activemq.yaml
  envsubst < /tmp/activemq.yaml > /tmp/activemq-updated.yaml

  oc apply -f /tmp/activemq-updated.yaml
fi    