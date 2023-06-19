resource "aws_s3_bucket" "example" {
  bucket = "samitbucket001"

  tags = {
    Name        = "samitbucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

#   routing_rule {
#     condition {
#       key_prefix_equals = "docs/"
#     }
#     redirect {
#       replace_key_prefix_with = "documents/"
#     }
#   }
}

output "website_domain" {
  value = aws_s3_bucket_website_configuration.example.website_domain
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.example.website_endpoint
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
}


locals {
    policy = jsonencode({
        "Statement": [
            {
                "Sid": "Statement1",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": "arn:aws:s3:::${aws_s3_bucket.example.id}/*"
            }
        ]
    })
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.example.id
  policy = local.policy
}