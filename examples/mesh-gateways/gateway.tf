locals {
  mgw_name_1 = "${var.name}-${var.datacenter_names[0]}-mesh-gateway"
  mgw_name_2 = "${var.name}-${var.datacenter_names[1]}-mesh-gateway"
}

module "dc1_gateway" {
  source          = "./gateway"
  name            = local.mgw_name_1
  region          = var.region
  vpc             = module.dc1_vpc
  private_subnets = module.dc1_vpc.private_subnets
  public_subnets  = module.dc1_vpc.public_subnets
  cluster         = module.dc1.ecs_cluster.arn
  log_group_name  = module.dc1.log_group.name
  datacenter      = var.datacenter_names[0]
  retry_join      = [module.dc1.dev_consul_server.server_dns]
  ca_cert_arn     = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_arn  = aws_secretsmanager_secret.gossip_key.arn

  enable_mesh_gateway_wan_peering = true

  additional_task_role_policies = [aws_iam_policy.execute_command.arn]
}

// DC2 gateway
module "dc2_gateway" {
  source          = "./gateway"
  name            = local.mgw_name_2
  region          = var.region
  vpc             = module.dc2_vpc
  private_subnets = module.dc2_vpc.private_subnets
  public_subnets  = module.dc2_vpc.public_subnets
  cluster         = module.dc2.ecs_cluster.arn
  log_group_name  = module.dc2.log_group.name
  datacenter      = var.datacenter_names[1]
  retry_join      = [module.dc2.dev_consul_server.server_dns]
  ca_cert_arn     = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_arn  = aws_secretsmanager_secret.gossip_key.arn

  //enable_mesh_gateway_wan_peering = true
  additional_task_role_policies = [aws_iam_policy.execute_command.arn]
}

// Policy that allows execution of remote commands in ECS tasks.
resource "aws_iam_policy" "execute_command" {
  name   = "${var.name}-ecs-execute-command"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

}



# // Ingress to mesh gateway 1
# resource "aws_security_group" "mesh_gateway_1" {
#   name   = "${local.mgw_name_1}-elb"
#   vpc_id = module.dc1_vpc.vpc_id

#   ingress {
#     description = "Access to the mesh gateway."
#     from_port   = 8433
#     to_port     = 8433
#     protocol    = "tcp"
#     # cidr_blocks = ["TODO: Mesh Gateway 2 IP/32"]
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group_rule" "ingress_from_mgw_elb_to_ecs" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.mesh_gateway_alb.id
#   security_group_id        = module.dc1_vpc.default_security_group_id
# }

# resource "aws_security_group_rule" "egress_from_mgw_elb_to_ecs" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.mesh_gateway_alb.id
#   security_group_id        = module.dc1_vpc.default_security_group_id
# }
