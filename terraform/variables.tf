variable "aws_region" {
  description = "AWS region for EKS cluster"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment in which cluster to be created"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "skilpulse-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.35"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "m7i-flex.large"
}

variable "node_desired_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_max_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "gateway_api_crd_version" {
  description = "Gateway api crd version"
  type        = string
  default     = "v1.2.1"
}