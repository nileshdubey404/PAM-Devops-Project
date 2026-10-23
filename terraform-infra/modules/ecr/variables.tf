variable "project_name" { type = string }
variable "environment" { type = string }
variable "keep_last_images" {
  description = "Number of images to retain in each repository."
  type        = number
  default     = 10
}
