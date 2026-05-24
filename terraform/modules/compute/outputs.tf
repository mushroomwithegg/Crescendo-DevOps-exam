output "asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "Name of the Auto Scaling Group"
}

output "asg_arn" {
  value       = aws_autoscaling_group.web.arn
  description = "ARN of the Auto Scaling Group"
}

output "launch_template_id" {
  value       = aws_launch_template.web.id
  description = "ID of the launch template"
}

output "instance_sg" {
  value       = aws_security_group.instance_sg.id
  description = "Security group ID for ASG instances"
}
