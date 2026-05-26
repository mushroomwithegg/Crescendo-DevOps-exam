output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.alb_distribution.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.alb_distribution.id
  description = "CloudFront distribution ID"
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
  description = "WAF Web ACL ARN"
}

output "waf_web_acl_id" {
  value       = aws_wafv2_web_acl.cloudfront_waf.id
  description = "WAF Web ACL ID"
}
