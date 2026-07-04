resource "aws_ssm_parameter" "certificate_arn" {
  name  = "/${var.project}/${var.environment}/certificate_arn"
  type  = "String"
  value = aws_acm_certificate.roboshop.arn
  overwrite = true
}