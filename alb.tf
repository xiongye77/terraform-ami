# Create Application Load Balancer Security Group

resource "aws_security_group" "dfsc_alb_sg" {
  vpc_id = aws_vpc.dfsc_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags = {
    Name        = "DFSC ALB Security Group"
    Terraform   = "True"   
  } 
}

# Create Application Load Balancer

resource "aws_lb" "dfsc_alb" {
  name               = "dfsc-app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dfsc_alb_sg.id]
  subnets = [
    aws_subnet.dfsc-public-1a.id,
    aws_subnet.dfsc-public-1b.id,
  ]
  enable_deletion_protection = false
  tags = {
    Name        = "DFSC Application Load Balancer"
    Terraform   = "True"   
  } 
}

resource "aws_lb_listener" "dfsc_https" {
  load_balancer_arn = aws_lb.dfsc_alb.arn
  port = 443 
  protocol = "HTTPS"
 ssl_policy        = "ELBSecurityPolicy-TLS-1-0-2015-04"
  certificate_arn   = "arn:aws:acm:ap-south-1:207880003428:certificate/8a42034f-90c6-4c07-8dc7-f2fe2e6205bf"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.dfsc-back-end-tg.arn
  }
}

resource "aws_lb_listener" "dfsc_https_redirect" {
  load_balancer_arn = aws_lb.dfsc_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create ALB Listner Backend Rule - HTTPS

resource "aws_lb_listener_rule" "dfsc_test1_https" {
  listener_arn = aws_lb_listener.dfsc_https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dfsc-back-end-tg.arn
  }
    condition {
    path_pattern {
      values = ["/test1/"]
    }
  }
}



#resource "aws_lb_listener_rule" "redirect_http_to_https" {
#  listener_arn = aws_lb_listener.dfsc_https.arn
#
#  action {
#    type = "redirect"
#
#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
#  condition {
#    field  = "host-header"
#    values = ["www.aconex.design"]
#  }
#}

# Create Frontend Target Group

resource "aws_lb_target_group" "dfsc-back-end-tg" {
  port = 80
  protocol = "HTTP"
  name = "dfsc-back-end-target-group"
  vpc_id = aws_vpc.dfsc_vpc.id
  stickiness {
    type = "lb_cookie"
    enabled = true
  }
  health_check {
    protocol = "HTTP"
    path = "/"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 10
  }
  tags = {
    Name        = "DFSC Back End Target Group"
    Terraform   = "True"
  }
}



# Create Security Group for ASG

resource "aws_security_group" "dfsc_asg_sg" {
  vpc_id = aws_vpc.dfsc_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
 ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      aws_security_group.dfsc_alb_sg.id
    ]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.dfsc_bastion_sg.id
    ]
  }
  tags = {
    Name        = "DFSC ASG Security Group"
    Terraform   = "true"
  }
}

# Create Launch Configuration

resource "aws_launch_configuration" "dfsc_launch_config" {
  name_prefix   = "DFSC Launch Configuration"
  image_id      = var.AMI_ID
  instance_type = "t2.micro"
  security_groups = [aws_security_group.dfsc_asg_sg.id]
  key_name = aws_key_pair.ssh-key.key_name
  #user_data       = data.template_file.userdata_template.rendered
  lifecycle {
    create_before_destroy = true
  }
}



# Create DFSC FrontEnd ASG

resource "aws_autoscaling_group" "dfsc_back_end" {
  name                 = "DFSC FrontEnd ASG"
  launch_configuration = aws_launch_configuration.dfsc_launch_config.name
  health_check_type    = "ELB"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1

  vpc_zone_identifier = [
    aws_subnet.dfsc-private-1a.id,
    aws_subnet.dfsc-private-1b.id
  ]
  target_group_arns = [aws_lb_target_group.dfsc-back-end-tg.arn]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "DFSC FrontEnd ASG"
    propagate_at_launch = true
  }
}



resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.dfsc_back_end.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.dfsc_back_end.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}


resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 60
  autoscaling_group_name = aws_autoscaling_group.dfsc_back_end.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.dfsc_back_end.name
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}


#data "template_file" "userdata_template" {
#  template = file("user-data.tpl")
#  vars = {
#    efs-endpoint    = "${aws_efs_file_system.dfsc_efs.dns_name}"
#  }
#}

   

#resource "aws_lb_listener_rule" "redirect_http_to_https" {
#  listener_arn = aws_lb_listener.back_end.arn
#
#  action {
#    type = "redirect"
#
#    redirect {
#      port        = "443"
#      protocol    = "HTTPS"
#      status_code = "HTTP_301"
#    }
#  }
#
#  condition {
#    field  = "host-header"
#    values = ["my-service.*.terraform.io"]
#    }
#  }

