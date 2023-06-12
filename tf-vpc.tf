# Vpc
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block         = var.cidr_block
  enable_dns_support = var.enable_dns_support
  instance_tenancy   = var.instance_tenancy

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.vpc_tags,
  )
}

# Subnet - Public
resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 && length(var.private_subnets) >= length(var.azs) ? length(var.public_subnets) : 0

  vpc_id                  = element(aws_vpc.main.*.id, count.index)
  cidr_block              = element(var.public_subnets, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format(
        "${var.public_subnet_suffix}-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}

# Subnet - Private
resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.private_subnets) > 0 && length(var.private_subnets) >= length(var.azs) ? length(var.private_subnets) : 0

  vpc_id            = element(aws_vpc.main.*.id, count.index)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format(
        "${var.private_subnet_suffix}-%s",
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}


# IGW
resource "aws_internet_gateway" "gw" {
  count  = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = element(aws_vpc.main.*.id, count.index)

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags
  )
}

# Rtb
resource "aws_route_table" "public" {
  count  = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = element(aws_vpc.main.*.id, count.index)

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.name)
    },
    var.tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id

  timeouts {
    create = "5m"
  }
}

# Rtb assoc
resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "sg" {
  count = var.create_vpc || var.security_group ? 1 : 0

  name        = var.security_group_name
  description = var.description
  vpc_id      = aws_vpc.main[0].id

  dynamic "ingress" {
    for_each = var.security_group_ingress
    content {
      description = lookup(ingress.value, "description", "")
      from_port   = lookup(ingress.value, "from_port", 0)
      to_port     = lookup(ingress.value, "to_port", 0)
      protocol    = lookup(ingress.value, "protocol", -1)
      cidr_blocks = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress
    content {
      description = lookup(egress.value, "description", "")
      from_port   = lookup(egress.value, "from_port", 0)
      to_port     = lookup(egress.value, "to_port", 0)
      protocol    = lookup(egress.value, "protocol", "-1")
      cidr_blocks = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
    }
  }
}