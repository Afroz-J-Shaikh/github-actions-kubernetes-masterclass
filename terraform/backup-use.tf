
# IAM policy — allow EKS nodes/pods to write to this bucket
resource "aws_iam_policy" "mysql_backup" {
  name = "${local.environment}-mysql-backup-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::skillpulse-mysql-backups-afroz",
          "arn:aws:s3:::skillpulse-mysql-backups-afroz/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_s3" {
  role       = module.eks.eks_managed_node_groups["skillpulse-ng"].iam_role_name
  policy_arn = aws_iam_policy.mysql_backup.arn
}