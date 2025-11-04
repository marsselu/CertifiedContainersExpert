#!/bin/bash
BACKUP_DIR=~/eks-backup-$(date +%Y%m%d-%H%M)
mkdir -p "$BACKUP_DIR"

echo "Exportando recursos..."
kubectl get all -A -o yaml > "$BACKUP_DIR/all-resources.yaml"

echo "Exportando PVCs e PVs..."
kubectl get pvc -A -o yaml > "$BACKUP_DIR/pvc.yaml"
kubectl get pv -o yaml > "$BACKUP_DIR/pv.yaml"

echo "Listando volumes EBS anexados..."
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/cluster/eks-cluster,Values=owned" \
  --query "Volumes[].{ID:VolumeId,State:State,Size:Size,AZ:AvailabilityZone}" \
  --output table > "$BACKUP_DIR/ebs-volumes.txt"

echo "Backup salvo em $BACKUP_DIR"

