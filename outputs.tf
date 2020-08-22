output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cdn_distribution.domain_name
  description = "Test"
}