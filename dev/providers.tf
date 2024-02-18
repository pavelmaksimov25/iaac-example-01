terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.blog.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.blog.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}
