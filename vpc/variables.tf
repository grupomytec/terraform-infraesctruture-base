variable "vpc_configuration" {
  // We will use a map with various aspects of the VPC, our map will be an object
  type = object({
    cidr_block = string
    // Our subnet attribute will be a list, and since subnets have several attributes, this will be a list of objects
    subnets = list(object({
      name       = string
      cidr_block = string
      public     = bool
    }))
  })
  // When we define a "default" value for a variable, it means that if we don't pass another value to Terraform during code execution, this will be the value
  default = {
    cidr_block = "10.0.0.0/18"
    subnets = [
      {
        name       = "private-a"
        cidr_block = "10.0.0.0/24"
        public     = false
      },
      {
        name       = "private-b"
        cidr_block = "10.0.10.0/24"
        public     = false
      },
      {
        name       = "private-c"
        cidr_block = "10.0.20.0/24"
        public     = false
      },
      {
        name       = "public-a"
        cidr_block = "10.0.1.0/24"
        public     = true
      },
      {
        name       = "public-b"
        cidr_block = "10.0.11.0/24"
        public     = true
      },
      {
        name       = "public-c"
        cidr_block = "10.0.21.0/24"
        public     = true
      },
    ]
  }
}