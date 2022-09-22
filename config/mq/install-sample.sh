# Enable Mananged Identity for AKS Cluster, it not already done

# Add AKS Contributor to Resource Group of VNet

# Deploy storage class

#Set environment variables; if using secure cluster connections, make sure you read
#in your server private key, certificate, and any public app key that needs to connect
export TARGET_NAMESPACE=${1:-"default"}

envsubt < mq-mqsc.yaml > mq-mqsc-values.yaml

kubectl apply -f mq-mqsc.values.yaml

kubectl create namespace $TARGET_NAMESPACE
kubectl config set-context --current --namespace= $TARGET_NAMESPACE

git clone https://github.com/ibm-messaging/mq-helm.git ~/mq-helm

helm install mq ~/mq-helm/charts/ibm-mq -f mq-aks-values.yaml

