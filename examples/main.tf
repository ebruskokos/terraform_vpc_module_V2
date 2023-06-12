module "vpc" {
  source                  = "../modules"
  name                    = "my-vpc"
  security_group_name     = "my-sg"
  description             = "security for infrastructure"
  cidr_block              = "10.0.0.0/16"
  enable_dns_support      = true
  instance_tenancy        = "default"
  public_subnets          = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20", "10.0.48.0/20"]
  private_subnets         = ["10.0.64.0/20", "10.0.80.0/20", "10.0.96.0/20", "10.0.112.0/20"]
  map_public_ip_on_launch = true
  azs                     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]

  security_group_ingress = [
    {
      description = "Mariadb access from VPC"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "76.198.149.152/32"
    },
    {
      description = "Mariadb access from VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "76.198.149.152/32"
    },
    {
      description = "Mariadb access from VPC"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = "76.198.149.152/32"
    }
  ]

  security_group_egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
