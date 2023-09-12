locals {
  enabled = module.this.enabled

  oidc_provider = tobool(var.create_oidc_provider) ? aws_iam_openid_connect_provider.provider[0] : data.aws_iam_openid_connect_provider.provider[0]

  projects = flatten([
    for repo in var.projects : [
      for workspace in repo.workspaces : {
        workspace = workspace
        project   = repo.project
        run_phase = repo.run_phase
      }
    ]
  ])
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      values   = [format("%s", one(aws_iam_openid_connect_provider.provider[0].client_id_list))]
      variable = format("%s:aud", var.url)
    }

    condition {
      test     = "ForAnyValue:StringLike"
      values   = [for org in local.projects : format("organization:%s:project:%s:workspace:%s:run_phase:%s", var.organisation, org.project, org.workspace, org.run_phase)]
      variable = format("%s:sub", var.url)
    }

    principals {
      identifiers = [local.oidc_provider.arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_openid_connect_provider" "provider" {
  count = tobool(local.enabled) && !tobool(var.create_oidc_provider) ? 1 : 0

  url = format("https://%s", var.url)
}

data "tls_certificate" "provider" {
  url = format("https://%s", var.url)
}

module "tfcloud" {
  source  = "git::https://github.com/jon-butterworth/tf-module-null-label"

  attributes = ["terraform-cloud", "role"]
  context = module.this.context
}

resource "aws_iam_role" "role" {
  count = tobool(local.enabled) ? 1 : 0

  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  description           = format("Role used by the %s Organisation.", var.organisation)
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  name                  = module.tfcloud.id
  path                  = var.iam_role_path
  permissions_boundary  = var.iam_role_permissions_boundary != "" ? var.iam_role_permissions_boundary : null
  tags                  = var.tags
}

resource "aws_iam_role_policy_attachment" "admin" {
  count = tobool(local.enabled) && tobool(var.attach_admin_policy) ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AdministratorAccess", data.aws_partition.current.partition)
  role       = aws_iam_role.role[0].id
}

resource "aws_iam_role_policy_attachment" "read_only" {
  count = tobool(local.enabled) && tobool(var.attach_read_only_policy) ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/ReadOnlyAccess", data.aws_partition.current.partition)
  role       = aws_iam_role.role[0].id
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = tobool(local.enabled) ? length(var.iam_role_policy_arns) : 0

  policy_arn = var.iam_role_policy_arns[count.index]
  role       = aws_iam_role.role[0].id
}

resource "aws_iam_openid_connect_provider" "provider" {
  count          = tobool(local.enabled) && tobool(var.create_oidc_provider) ? 1 : 0
  client_id_list = var.provider_client_id_list

  tags            = var.tags
  thumbprint_list = [data.tls_certificate.provider.certificates[0].sha1_fingerprint]
  url             = format("https://%s", var.url)
}

