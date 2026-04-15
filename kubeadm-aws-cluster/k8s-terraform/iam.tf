# 1. The Policy: What the nodes are ALLOWED to do
resource "aws_iam_policy" "external_dns" {
  name        = "AllowExternalDNSUpdates"
  description = "Allows ExternalDNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:ChangeResourceRecordSets"]
        Effect   = "Allow"
        Resource = ["arn:aws:route53:::hostedzone/${aws_route53_zone.private.zone_id}"]
      },
      {
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

# 2. The Role: The "Job Description" for the EC2 instance
resource "aws_iam_role" "k8s_node_role" {
  name = "k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.k8s_node_role.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# 4. The Profile: The actual container we "clip" onto the EC2 instance
resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "k8s-node-profile"
  role = aws_iam_role.k8s_node_role.name
}

resource "aws_iam_policy" "aws_lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Allows K8s to manage AWS Load Balancers"

  # This is a standard policy provided by AWS
  policy = file("${path.module}/iam_policy_alb.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.k8s_node_role.name
  policy_arn = aws_iam_policy.aws_lb_controller.arn
}