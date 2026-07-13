module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets   # 🔥 IMPORTANT

  eks_managed_node_groups = {
    chess_nodes = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.small"]

      # 🔥 PUBLIC NODE CONFIG
      associate_public_ip_address = true
    }
  }
}