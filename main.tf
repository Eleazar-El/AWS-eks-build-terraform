provider "aws" {
  region  = "us-east-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = "default"
}


locals {

  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"

  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }
}

data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks_cluster.eks_cluster_id
    kubernetes_config_map_id = module.eks_cluster.kubernetes_config_map_id
    cluster_endpoint         = module.eks_cluster.eks_cluster_endpoint
  }
}

module "vpc" {
  source      = "./modules/vpc"
  region      = "us-east-2"
  environment = "Staging"
}


module "eks_cluster" {
  source = "./modules/eks-cluster"

  region                       = "us-east-2"
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.public_subnets
  kubernetes_version           = "1.21"
  #local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = true
  enabled_cluster_log_types    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_period = 30

  cluster_encryption_config_enabled                         = var.cluster_encryption_config_enabled
  cluster_encryption_config_kms_key_id                      = var.cluster_encryption_config_kms_key_id
  cluster_encryption_config_kms_key_enable_key_rotation     = var.cluster_encryption_config_kms_key_enable_key_rotation
  cluster_encryption_config_kms_key_deletion_window_in_days = var.cluster_encryption_config_kms_key_deletion_window_in_days
  cluster_encryption_config_kms_key_policy                  = var.cluster_encryption_config_kms_key_policy
  cluster_encryption_config_resources                       = var.cluster_encryption_config_resources

  #addons = var.addons

  create_security_group = true

  
  #allowed_security_group_ids = [module.vpc.vpc_default_security_group_id]
  #allowed_cidr_blocks        = [module.vpc.vpc_cidr_block]

}

# data "aws_vpc" "main" {
#     #id = var.vpc_id

#     default = false
# #     tags    = {
# #     Name    = "${var.environment}-vpc-${var.region}"
# #   }
# }

module "eks_node_group" {
  source  = "./modules/eks-node-group"

  subnet_ids        = module.vpc.private_subnets
  cluster_name      = data.null_data_source.wait_for_cluster_and_kubernetes_configmap.outputs["cluster_name"]
  instance_types    = ["t3.micro"]
  desired_size      = 2
  min_size          = 1
  max_size          = 3
  disk_size         = 15
  kubernetes_labels = var.kubernetes_labels
  vpc_id            = module.vpc.vpc_id  

  #Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on = module.eks_cluster.kubernetes_config_map_id

  #context = module.this.context
}
