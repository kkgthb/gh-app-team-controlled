module "github_org_config" {
  source = "./modules/github/orgconfig"
  providers = {
    github = github.demo
  }
  workload_nickname = var.workload_nickname
  gh_org_name       = var.gh_org_name
}
