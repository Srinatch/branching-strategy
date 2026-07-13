module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "chess-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  # 🔥 ONLY PUBLIC SUBNETS (NO PRIVATE)
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false   # ❌ COST SAVED
  enable_dns_hostnames = true
}