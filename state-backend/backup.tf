resource "aws_s3_bucket" "mysql_backup" {
  # Created once, shared across envs via prefix folders
  bucket = "skillpulse-mysql-backups-afroz"

  tags = {
    Name        = "skillpulse-mysql-backups"
    Project     = "skillpulse"
    ManagedBy   = "terraform"
    Environment = "shared"
  }
}

resource "aws_s3_bucket_versioning" "mysql_backup" {
  bucket = aws_s3_bucket.mysql_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mysql_backup" {
  bucket = aws_s3_bucket.mysql_backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "mysql_backup" {
  bucket                  = aws_s3_bucket.mysql_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "mysql_backup" {
  bucket = aws_s3_bucket.mysql_backup.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    expiration {
      days = 90 # keep 90 days, adjust as needed
    }
  }
}

output "backup_bucket_name" {
  description = "Backup bucket name(taking mysql pod backup)"
  value       = aws_s3_bucket.mysql_backup.bucket
}

