output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ips" {
  value = aws_instance.workers[*].public_ip
}

output "vpc_id" {
  value       = aws_vpc.k8s_vpc.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  description = "IDs of the public subnets for the ALB"
  value       = [
    aws_subnet.k8s_subnet.id,
    aws_subnet.k8s_subnet_2.id
  ]
}

output "alb_sg_id" {
  description = "The ID of the security group to be used in Ingress annotations"
  value       = aws_security_group.alb_sg.id
}

# output "hosted_zone_id" {
#   value = aws_route53_zone.private.zone_id
# }
