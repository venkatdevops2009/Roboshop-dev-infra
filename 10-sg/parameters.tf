resource "aws_ssm_parameter" "sg_id" {
  count = length(var.sg_names)
  name  = "/${var.project}/${var.environment}/${var.sg_names[count.index]}_sg_id" # /roboshop/dev/backend_alb_sg_id, /roboshop/dev/mongodb_sg_id
  type  = "String"
  value = module.sg[count.index].sg_id
  overwrite = true
}