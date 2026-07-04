locals {
    mongodb_sg_id = data.aws_ssm_parameter.mongodb_sg_id.value
    redis_sg_id = data.aws_ssm_parameter.redis_sg_id.value
    rabbitmq_sg_id = data.aws_ssm_parameter.rabbitmq_sg_id.value
    mysql_sg_id = data.aws_ssm_parameter.mysql_sg_id.value
    common_name = "${var.project}-${var.environment}"
    
    ami_id = data.aws_ami.joindevops.id
    database_subnet_id = split(",", data.aws_ssm_parameter.database_subnet_ids.value)[0] # roboshop-dev-public-1a
    common_tags = {
        Project = "${var.project}"
        Environment = "${var.environment}"
        Terraform = "true"
    }
}