# Learner Lab restriction: Cannot create IAM roles or users
# GitHub Actions will use AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY secrets instead
# The LabRole pre-created by Learner Lab has sufficient permissions for EKS operations

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
