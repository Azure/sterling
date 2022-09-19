#Set environment variables; if using secure cluster connections, make sure you read
#in your server private key, certificate, and any public app key that needs to connect
export TARGET_NAMESPACE=${1:-"default"}
#export QM_KEY=$(cat server.key | base64 | tr -d '\n')
#export QM_CERT=$(cat server.crt | base64 | tr -d '\n')
#export APP_CERT=$(cat application.crt | base64 | tr -d '\n')

envsubt < mq-mqsc.yaml > mq-mqsc-values.yaml

kubectl apply -f mq-mqsc.values.yaml

git clone https://github.com/ibm-messaging/mq-helm.git ~/mq-helm

helm install secureapphelm ~/mq-helm/charts/ibm-mq -f mq-aks-values.yaml

