data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "instance_sg" {
  name   = "${var.name}-instance-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-instance-sg" }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.name}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for EC2 Instance Connect
resource "aws_iam_role_policy" "ec2_instance_connect" {
  name_prefix = "${var.name}-ec2-connect-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2-instance-connect:SendSSHPublicKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.name}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name
}

# Allow incoming traffic from ALB security group
resource "aws_security_group_rule" "allow_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = var.alb_security_group_id
}

# Allow EC2 Instance Connect
resource "aws_security_group_rule" "allow_ec2_instance_connect" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ec2_instance_connect_cidr]
  security_group_id = aws_security_group.instance_sg.id
  description       = "EC2 Instance Connect (${var.ec2_instance_connect_cidr})"
}

# Launch template for ASG
resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log)
              exec 2>&1
              
              echo "[$(date)] Starting user data script"
              
              # Install httpd and ec2-instance-connect before attempting to write to webroot
              echo "[$(date)] Installing packages..."
              amazon-linux-extras install epel -y
              yum install -y nginx ec2-instance-connect
              
              # Enable and start nginx service
              echo "[$(date)] Starting nginx service..."
              systemctl enable nginx
              systemctl start nginx
              
              # Verify nginx is running before writing to webroot
              sleep 2
              if ! systemctl is-active --quiet nginx; then
                echo "[$(date)] ERROR: nginx failed to start"
                exit 1
              fi
              
              # Now write to webroot directory
              echo "[$(date)] Creating health check page..."
              echo "<h1>Hello from Nginx on Amazon Linux!</h1>" > /usr/share/nginx/html/index.html
              
              echo "[$(date)] User data script completed successfully"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-web" }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "${var.name}-web-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-web-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
