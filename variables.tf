variable "attach_admin_policy" {
  default     = false
  type        = bool
}

variable "attach_read_only_policy" {
  default     = true
  type        = bool
}

variable "create_oidc_provider" {
  default     = true
  type        = bool
}

variable "force_detach_policies" {
  default     = false
  type        = string
}

variable "organisation" {
  type        = string
}

variable "projects" {
  type = list(object({
    project    = string
    run_phase  = string
    workspaces = list(string)
  }))
  default = [{
    project    = null
    run_phase  = null
    workspaces = null
  }]
}

variable "iam_role_name" {
  default     = "terraform-cloud"
  type        = string
}

variable "iam_role_path" {
  default     = "/"
  type        = string
  sensitive   = false
}

variable "iam_role_permissions_boundary" {
  default     = ""
  type        = string
  sensitive   = false
}

variable "iam_role_policy_arns" {
  default     = []
  type        = list(string)
  sensitive   = false
}

variable "max_session_duration" {
  default     = 3600
  type        = number
  sensitive   = false
}

variable "provider_client_id_list" {
  default     = ["aws.workload.identity"]
  type        = list(string)
  sensitive   = false
}

variable "url" {
  type        = string
  default     = "app.terraform.io"
  sensitive   = false
}

variable "tags" {
  default     = {}
  type        = map(string)
  sensitive   = false
}