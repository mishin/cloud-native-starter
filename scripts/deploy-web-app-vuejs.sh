#!/bin/bash

root_folder=$(cd $(dirname $0); cd ..; pwd)

logname="deploy-web-app-vuejs.log"

function setupLog(){
 cd "${root_folder}/scripts"
 readonly LOG_FILE="${root_folder}/scripts/$logname"
 touch $LOG_FILE
 exec 3>&1 # Save stdout
 exec 4>&2 # Save stderr
 exec 1>$LOG_FILE 2>&1
 exec 3>&1
}

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function configureVUEminikubeIP(){
  cd ${root_folder}/web-app-vuejs/src/components
  
  _out configureVUEIP
  minikubeip=$(minikube ip)

  _out _copy App.vue template definition
  rm "Home.vue"
  cp "Home-template.vue" "Home.vue"
  sed "s/MINIKUBE_IP/$minikubeip/g" Home-template.vue > Home.vue
  
  cd ${root_folder}/web-app-vuejs
}

function setup() {
  _out Deploying web-app-vuejs
  
  cd ${root_folder}/web-app-vuejs
  kubectl delete -f deployment/kubernetes.yaml
  kubectl delete -f deployment/istio.yaml
  
  configureVUEminikubeIP

  eval $(minikube docker-env) 
  docker build -f Dockerfile -t web-app:1 .

  kubectl apply -f deployment/kubernetes.yaml
  kubectl apply -f deployment/istio.yaml

  minikubeip=$(minikube ip)
  nodeport=$(kubectl get svc web-app --output 'jsonpath={.spec.ports[*].nodePort}')
  _out Minikube IP: ${minikubeip}
  _out NodePort: ${nodeport}
  
  _out Done deploying web-app-vuejs
  _out Open the app: http://${minikubeip}:${nodeport}/
}

#exection starts from here

setupLog
setup