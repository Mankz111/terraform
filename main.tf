provider "aws" {
  region = "eu-west-1"
}

resource "aws_ecr_repository" "docker-repo" {
  name                 = "ecr-repo"
  image_tag_mutability = "MUTABLE"

}

resource "aws_iam_role" "terraform-role" {
  name = "terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.terraform-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "cluster" {
  name = "meu-cluster"

}

resource "aws_ecs_task_definition" "task" {

  family                   = "minha-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.terraform-role.arn

  container_definitions = jsonencode([
    {
      name      = "minha-app"
      image     = "${aws_ecr_repository.docker-repo.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])

}

resource "aws_security_group" "sg" {
  name        = "minha-app-sg"
  description = "Permite trafego HTTP"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_ecs_service" "service" {
  name            = "minha-app-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-04bfad2270a90f3d7", "subnet-0328b97c5874e5d72", "subnet-06d157bc4fbd63eb8"]
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}
