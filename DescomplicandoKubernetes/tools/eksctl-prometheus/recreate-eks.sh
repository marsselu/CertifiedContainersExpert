#!/bin/bash
REGION="us-east-1"
CLUSTER_NAME="eks-cluster"
BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
  echo "Uso: ./recreate-eks.sh <caminho_para_backup.yaml>"
  exit 1
fi

echo "Criando novo cluster EKS..."
#eksctl create cluster --name "$CLUSTER_NAME" --region "$REGION"
eksctl create cluster --name "$CLUSTER_NAME" --region "$REGION" --node-type t3.medium


echo "Aplicando recursos do backup..."
kubectl apply -f "$BACKUP_FILE"

echo "Cluster recriado e restaurado."

