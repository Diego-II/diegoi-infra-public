# ===========================================================================
# project-b project infrastructure.
#
# Everything here lives INSIDE account 333333333333. Organizations, OUs, SCPs,
# account vending and the DNS delegation are NOT this repo's job -- they belong
# to diegoi-infra.
#
# The bucket below is a starter so `terraform apply` does something real on
# day one. Replace it with whatever the project actually needs.
# ===========================================================================

# --- DNS --------------------------------------------------------------------
# project-b.example.net is delegated to this account by diegoi-infra, which owns the
# zone and the parent NS record. Look it up rather than declaring it -- two
# Terraform states owning one zone is how zones get orphaned.

data "aws_route53_zone" "this" {
  name = "project-b.example.net."
}

# Records inside the zone ARE this repo's job. Example:
#
#   resource "aws_route53_record" "api" {
#     zone_id = data.aws_route53_zone.this.zone_id
#     name    = "api.project-b.example.net"
#     type    = "A"
#     ...
#   }

resource "aws_s3_bucket" "data" {
  bucket = var.data_bucket_name
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Raw scraped data is re-fetchable; expire noise instead of paying to keep it.
# The management account's budget ceiling is $50 -- this account shares it.
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "expire-raw"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    expiration {
      days = 90
    }
  }
}
