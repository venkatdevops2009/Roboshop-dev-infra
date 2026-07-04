locals {
  cachingOptmized = data.aws_cloudfront_cache_policy.cachingOptmized.id
  cachingDisabled = data.aws_cloudfront_cache_policy.cachingDisabled.id
  common_tags = {
        Project = "${var.project}"
        Environment = "${var.environment}"
        Terraform = "true"
   }
  certificate_arn = data.aws_ssm_parameter.certificate_arn.value
}
