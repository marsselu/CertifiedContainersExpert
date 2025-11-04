#!/bin/bash
REGION="us-east-1"
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:eks:cluster-name,Values=eks-cluster" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

[ -z "$INSTANCE_IDS" ] && echo "Nenhuma instância em execução encontrada." && exit 0
echo "Parando instâncias: $INSTANCE_IDS"
aws ec2 stop-instances --region "$REGION" --instance-ids $INSTANCE_IDS
echo "Parada solicitada."

