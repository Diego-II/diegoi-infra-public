terraform {
  backend "s3" {
    bucket       = "diegoi-tfstate-111111111111"
    key          = "accounts/homelab/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
