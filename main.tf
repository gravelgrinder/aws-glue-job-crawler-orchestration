terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

###############################################################################
### Create Raw S3 Bucket
###############################################################################
resource "aws_s3_bucket" "example" {
  bucket = "tf-claim-processing-bucket"
  force_destroy = true

  tags = {
      Name        = "TF AWS Glue Job Crawler Orchestration"
      GitRepo     = "aws-glue-job-crawler-orchestration"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls   = true
  ignore_public_acls  = true
  block_public_policy = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expire_version" {
  bucket = aws_s3_bucket.example.id

  rule {
    id      = "expire_version"
    status  = "Enabled"
    filter {prefix = ""}
    expiration {days = 1}
    noncurrent_version_expiration {noncurrent_days = 1}
    abort_incomplete_multipart_upload {days_after_initiation = 1}
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_version" {
  bucket = aws_s3_bucket.example.id

  rule {
    id      = "delete_version"
    status  = "Enabled"
    filter {prefix = ""}
    expiration {expired_object_delete_marker = true}
  }
}
###############################################################################



################################################################################
### Create IAM Role for Glue Jobs
################################################################################
resource "aws_iam_role" "glue" {
  name = "tf-glue-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "glue.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue-service-role" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue" {
  name = "tf-glue-policy"
  role = aws_iam_role.glue.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::tf-claim-processing-bucket/Input/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::tf-claim-processing-bucket/Output/*"
            ]
        }
    ]
}
POLICY
}
################################################################################


################################################################################
### Create AWS Glue Job: ProcessMembers
################################################################################
#resource "aws_glue_job" "payment_engine" {
#  name     = "staging-to-processed"
#  role_arn = aws_iam_role.example.arn

#  command {
#    script_location = "s3://${aws_s3_bucket.example.bucket}/example.py"
#  }
#}
################################################################################


################################################################################
### Create AWS Glue Job: ProcessClaims
################################################################################

################################################################################

###REMOVE###resource "aws_glue_catalog_database" "payment_engine" {
###REMOVE###  name = "payment_engine"
###REMOVE###}
###REMOVE###
###REMOVE###resource "aws_glue_crawler" "payment_engine" {
###REMOVE###  database_name = aws_glue_catalog_database.payment_engine.name
###REMOVE###  name          = "Staging"
###REMOVE###  role          = aws_iam_role.glue.arn
###REMOVE###
###REMOVE###  s3_target {
###REMOVE###    path = "s3://${aws_s3_bucket.bucket-staging.bucket}"
###REMOVE###  }
###REMOVE###
###REMOVE###  provisioner "local-exec" {
###REMOVE###    command = "aws glue start-crawler --name ${self.name}"
###REMOVE###  }
###REMOVE###}
###REMOVE###
###REMOVE###resource "aws_iam_role" "glue" {
###REMOVE###  name = "tf-glue-payment-engine-role"
###REMOVE###
###REMOVE###  assume_role_policy = <<EOF
###REMOVE###{
###REMOVE###    "Version": "2012-10-17",
###REMOVE###    "Statement": [
###REMOVE###        {
###REMOVE###        "Effect": "Allow",
###REMOVE###        "Principal": {
###REMOVE###            "Service": "glue.amazonaws.com"
###REMOVE###        },
###REMOVE###        "Action": "sts:AssumeRole"
###REMOVE###        }
###REMOVE###    ]
###REMOVE###}
###REMOVE###EOF
###REMOVE###}
###REMOVE###
###REMOVE###resource "aws_iam_role_policy_attachment" "glue-service-role" {
###REMOVE###  role       = aws_iam_role.glue.name
###REMOVE###  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
###REMOVE###}
###REMOVE###
###REMOVE###resource "aws_iam_role_policy" "glue" {
###REMOVE###  name = "tf-glue-payment-engine-policy"
###REMOVE###  role = aws_iam_role.glue.id
###REMOVE###  policy = <<POLICY
###REMOVE###{
###REMOVE###    "Version": "2012-10-17",
###REMOVE###    "Statement": [
###REMOVE###        {
###REMOVE###            "Effect": "Allow",
###REMOVE###            "Action": [
###REMOVE###                "s3:GetObject",
###REMOVE###                "s3:PutObject"
###REMOVE###            ],
###REMOVE###            "Resource": [
###REMOVE###                "arn:aws:s3:::octank-2021-staging-bucket*"
###REMOVE###            ]
###REMOVE###        },
###REMOVE###        {
###REMOVE###            "Effect": "Allow",
###REMOVE###            "Action": [
###REMOVE###                "s3:PutObject"
###REMOVE###            ],
###REMOVE###            "Resource": [
###REMOVE###                "arn:aws:s3:::octank-2021-processing-bucket*"
###REMOVE###            ]
###REMOVE###        }
###REMOVE###    ]
###REMOVE###}
###REMOVE###POLICY
###REMOVE###}
###REMOVE###
###REMOVE####resource "aws_glue_job" "payment_engine" {
###REMOVE####  name     = "staging-to-processed"
###REMOVE####  role_arn = aws_iam_role.example.arn
###REMOVE###
###REMOVE####  command {
###REMOVE####    script_location = "s3://${aws_s3_bucket.example.bucket}/example.py"
###REMOVE####  }
###REMOVE####}


output "s3_bucket_name" {
  value = aws_s3_bucket.example.bucket_regional_domain_name
}