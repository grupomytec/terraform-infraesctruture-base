// "this" is just a logical name that we will use to reference the VPC within Terraform, it does not apply to the provider
resource "aws_vpc" "this" {
  // Value is being taken via reference of variables.tf file
  cidr_block = var.vpc_configuration.cidr_block
  // That way we can resolve names of instances and other hosts that are on our network
  enable_dns_hostnames = true
  enable_dns_support   = true
}

// Internet Gateway works for region as a whole, we only have one, so we also use "this"
resource "aws_internet_gateway" "this" {
  // We are using the VPC "this" reference and the "id" attribute, so we don't need to change the code if the vpc and the id change
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "this" {
  // For each element or each resource in a list it creates an instance, which in this case is the subnet
  for_each = { for subnet in var.vpc_configuration.subnets : subnet.name => subnet }

  // In the for_each map we created above, we can get the subnet.name with 'each.key' and the subnet itself with 'each.value'
  // Above the configuration of each subnet
  availability_zone_id    = local.az_pairs[each.key]
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = each.key
  }
}

// Creating the Nat Gateway, we need a Nat Gateway for each privet subnet
resource "aws_nat_gateway" "this" {
  // We using the function 'toset()' because we need that each value in the list be unique
  for_each = toset(local.private_subnets)

  // We need a public IP that allow to the private subnet access the internet, and we're going to use an ElasticIP for this
  allocation_id = aws_eip.nat_gateway[each.value].id
  subnet_id     = aws_subnet.this[local.subnet_pairs[each.value]].id
}

// Creating ElasticIP for the Nat Gateway
// Here we don't use the name 'this' as we may need other ElasticIP's in the VPC
resource "aws_eip" "nat_gateway" {
  // For each private subnet we need an ElasticIP that will be attached to the public subnet's Nat Gateway
  for_each = toset(local.private_subnets)
  vpc      = true

  // There is a dependency for this ElasticIP to be created, and this dependency is that the Internet Gateway has been created
  depends_on = [aws_internet_gateway.this]
}

# Routes -------

// Creating the public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

// Creating route to internet gateway
resource "aws_route" "internet_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
}

// Creating public route table association
resource "aws_route_table_association" "public" {
  // Making unique values ​​coming from the for_each list
  for_each       = toset(local.public_subnets)
  // We need the subnet id, and we need to get the subnet we are trying to configure inside for_each
  subnet_id      = aws_subnet.this[each.value].id
  // Relating the subnet id to the route table id
  route_table_id = aws_route_table.public.id
}

// Creating the private route table
resource "aws_route_table" "private" {
  for_each = toset(local.private_subnets)
  vpc_id   = aws_vpc.this.id
}

// Creating the route to the Nat Gateway
// Separate routes and tables, as each private subnet will talk to the nat gateway of its respective public subnet
// Here we first create the route for each route table to the Nat Gateway
resource "aws_route" "nat_gateway" {
  for_each = toset(local.private_subnets)

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private[each.value].id
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

// Creating the private route table association
// Here we will create the association of route tables to private subnets
resource "aws_route_table_association" "private" {
  for_each       = toset(local.private_subnets)
  subnet_id      = aws_subnet.this[each.value].id
  route_table_id = aws_route_table.private[each.value].id
}