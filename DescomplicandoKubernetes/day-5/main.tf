provider "aws" {
  region = "us-east-1"
}

# -------------------
# VPC e Subnet padrão (já existente na AWS)
# -------------------
data "aws_vpc" "default" {
  default = true
}

# Pega todas as subnets da VPC default
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Usaremos a primeira subnet para as instâncias
locals {
  default_subnet_id = data.aws_subnets.default_vpc_subnets.ids[0]
}

# -------------------
# Security Group (Kubernetes Cluster + SSH)
# -------------------
resource "aws_security_group" "k8s_cluster_sg" {
  name        = "k8s-cluster-sg"
  description = "Permite trafego interno e portas Kubernetes + SSH"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "Acesso SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["200.165.95.78/32"] #ip local
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # etcd
  ingress {
    description = "etcd server client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet / Control Plane / Scheduler
  ingress {
    description = "Kubernetes internal components"
    from_port   = 10250
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePorts
  ingress {
    description = "Kubernetes NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress liberado
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-cluster-sg"
  }
}

# -------------------
# Instâncias EC2 (1 control-plane + 2 workers)
# -------------------
resource "aws_instance" "k8s_nodes" {
  count                  = 3
  ami                    = "ami-0c398cb65a93047f2" # Ubuntu 24.04 LTS us-east-1
  instance_type          = "t2.medium"              # Free Tier elegível
  subnet_id              = local.default_subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_cluster_sg.id]
  key_name               = "pick_aws"       # Substitua pelo nome da sua chave EC2

  tags = {
    Name = "k8s-node-${count.index + 1}"
    Role = count.index == 0 ? "control-plane" : "worker"
  }
}

