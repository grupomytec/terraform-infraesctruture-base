/*
When we need resources that belong to the provider and not our code, we need to check if they exist. In this case we need the Data Source to check if the "IDs" 
of the availability zones are still available
*/
data "aws_availability_zones" "available" {
  state = "available"
}