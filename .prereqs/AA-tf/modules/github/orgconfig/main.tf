# "Hello world" query I can remove later
data "github_organization" "my_gh_org" {
  name = var.gh_org_name
}
