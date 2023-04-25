variable "project" {
  description = "The name of the Google Cloud project to use for resources."
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the CDN."
  type        = string
}

variable "managed_zone" {
  description = "The name of the Google Cloud DNS managed zone for the domain name."
  type        = string
}
