//We need to ensure that the public and private subnets are paired for each AZ, for this we use a Terraform feature to manipulate local values, which is called "locals"
locals {
  // Separating Private Subnets
  private_subnets = sort([for subnet in var.vpc_configuration.subnets : subnet.name if subnet.public == false])
  // Separating Public Subnets
  public_subnets = sort([for subnet in var.vpc_configuration.subnets : subnet.name if subnet.public == true])
  // Using the Private Subnet Amount Reference to Create the Right Amount of AZ's
  azs = sort(slice(data.aws_availability_zones.available.zone_ids, 0, length(local.private_subnets)))
  // Using zipmap to create subnet pairs based on identifiers
  subnet_pairs = zipmap(local.private_subnets, local.public_subnets)

  // Linking the subnet pairs to each of the 3 AZ's in an organized way
  az_pairs = merge(
    zipmap(local.private_subnets, local.azs),
    zipmap(local.public_subnets, local.azs)
  )
}