resource "aws_s3_bucket" "foo" {
  bucket = "tfpocbucket001"

  tags = {
    Environment = "Dev"
  }
}