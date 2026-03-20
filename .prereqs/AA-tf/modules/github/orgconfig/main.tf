data "github_organization" "my_gh_org" {
  name = var.gh_org_name
}

# ---------------------------------------------------------------------------
# Repo B — the private repo whose contents Repo A's workflow will read
# ---------------------------------------------------------------------------

resource "github_repository" "my_gh_repo_b" {
  name       = local.my_gh_repo_b_name
  visibility = "private"
  auto_init  = true
}

resource "github_repository_file" "my_gh_repo_b_file_helloworld" {
  depends_on          = [github_repository.my_gh_repo_b]
  repository          = github_repository.my_gh_repo_b.name
  file                = "helloworld.txt"
  content             = "Hello, world!  This file lives in Repo B."
  branch              = "main"
  commit_message      = "Add helloworld.txt"
  overwrite_on_create = true
}

# ---------------------------------------------------------------------------
# GitHub App — looked up by slug; degrades gracefully to empty strings on 404
#
# TODO manually: create the "${local.my_gh_app_slug}" GitHub App in the org,
# then generate a private key (.pem) and store its contents in the org secret
# named local.my_gh_org_secret_name.
# ---------------------------------------------------------------------------

data "external" "my_gh_app" {
  program = [
    "pwsh", "-Command",
    "$r = gh api /apps/${local.my_gh_app_slug} 2>$null; if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($r)) { '{\"app_id\":\"\",\"node_id\":\"\",\"name\":\"\"}' } else { $r | ConvertFrom-Json | Select-Object @{n='app_id';e={$_.id -as [string]}}, @{n='node_id';e={$_.node_id}}, @{n='name';e={$_.name}} | ConvertTo-Json -Compress }"
  ]
}

# Looks up the org installation ID for the app.
# Returns empty string if the app has no org installation yet.
#
# TODO manually: install the app into the org and scope it to Repo B at:
# https://github.com/apps/${local.my_gh_app_slug}/installations/new/permissions?target_id=${data.github_organization.my_gh_org.id}&target_type=Organization
data "external" "my_gh_app_installation" {
  depends_on = [data.external.my_gh_app]
  count      = data.external.my_gh_app.result.app_id != "" ? 1 : 0
  program = [
    "pwsh", "-Command",
    "$r = gh api /orgs/${var.gh_org_name}/installations --jq '[.installations[] | select(.app_slug == \"${local.my_gh_app_slug}\") | {installation_id: (.id | tostring)}] | first'; if ([string]::IsNullOrWhiteSpace($r) -or $r -eq 'null') { '{\"installation_id\":\"\"}' } else { $r }"
  ]
}

# ---------------------------------------------------------------------------
# Org secret — the app's PEM key, pre-created manually and read back here
# ---------------------------------------------------------------------------

data "github_actions_organization_secrets" "my_gh_org_secrets_all_readonly" {
  # There is no point moving on this section if the app is not yet installed
  # since it holds the PEM key of the app
  depends_on = [data.external.my_gh_app_installation]
  count      = (length(data.external.my_gh_app_installation) > 0 && data.external.my_gh_app_installation[0].result.installation_id != "") ? 1 : 0
}

locals {
  my_gh_org_secret_from_data = one([
    for s in flatten([for ds in data.github_actions_organization_secrets.my_gh_org_secrets_all_readonly : ds.secrets]) : s
    if lower(s.name) == lower(local.my_gh_org_secret_name)
  ])
}

# ---------------------------------------------------------------------------
# Repo A — the private repo whose workflow reads from Repo B via the app token
# ---------------------------------------------------------------------------

resource "github_repository" "my_gh_repo_a" {
  depends_on = [data.github_actions_organization_secrets.my_gh_org_secrets_all_readonly]
  count      = local.my_gh_org_secret_from_data != null ? 1 : 0
  name       = local.my_gh_repo_a_name
  visibility = "private"
  auto_init  = true
}

resource "github_actions_organization_secret_repository" "my_gh_org_secret_assignment_to_repo_a" {
  depends_on    = [github_repository.my_gh_repo_a]
  count         = (length(github_repository.my_gh_repo_a) > 0 && local.my_gh_org_secret_from_data != null) ? 1 : 0
  secret_name   = local.my_gh_org_secret_from_data.name
  repository_id = github_repository.my_gh_repo_a[0].repo_id
}

resource "github_repository_file" "my_gh_repo_a_file_workflow" {
  depends_on = [
    github_repository.my_gh_repo_a,
    github_actions_organization_secret_repository.my_gh_org_secret_assignment_to_repo_a,
  ]
  count = (
    length(github_repository.my_gh_repo_a) > 0 &&
    length(github_actions_organization_secret_repository.my_gh_org_secret_assignment_to_repo_a) > 0 &&
    data.external.my_gh_app.result.app_id != ""
  ) ? 1 : 0
  repository = github_repository.my_gh_repo_a[0].name
  file       = ".github/workflows/read-repo-b.yml"
  content = templatefile("${path.module}/templates/workflow.yml.tftpl", {
    app_id          = data.external.my_gh_app.result.app_id
    org_secret_name = local.my_gh_org_secret_name
    repo_b_name     = local.my_gh_repo_b_name
    gh_org_name     = var.gh_org_name
  })
  branch              = "main"
  commit_message      = "Add workflow to read helloworld.txt from Repo B"
  overwrite_on_create = true
}
