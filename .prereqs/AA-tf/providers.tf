# Configure the GitHub provider
provider "github" {
  alias = "demo"
  owner = var.gh_org_name
}
