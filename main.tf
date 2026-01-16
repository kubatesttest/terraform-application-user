# Application Layer - Compute resources that use infrastructure layer outputs
# This layer creates: EC2 instance

# Local values referencing infrastructure layer outputs
# Key pattern: Local values from terraform_remote_state for cleaner references
locals {
  # These come from the infrastructure layer via terraform_remote_state
  sg_id          = data.terraform_remote_state.infrastructure.outputs.security_group_id
  environment    = data.terraform_remote_state.infrastructure.outputs.environment
  deployment_tag = data.terraform_remote_state.infrastructure.outputs.deployment_tag

  # Name prefix for consistent resource naming
  name_prefix = "lab5-${var.project}-${local.environment}"
}

# EC2 instance using infrastructure from the other layer
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [local.sg_id]    # From infrastructure layer

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Create a simple web page
    cat > /var/www/html/index.html <<'HTMLEOF'
    <!DOCTYPE html>
    <html>
    <head><title>${var.project} Web Server</title></head>
    <body>
      <h1>Web Server</h1>
      <p>Environment: ${local.environment}</p>
    </body>
    </html>
    HTMLEOF
  EOF

  tags = {
    Name       = "${local.name_prefix}-web"
    Deployment = local.deployment_tag
    LastUpdated = "Step16-Demo"
  }
}
