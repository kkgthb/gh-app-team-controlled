# Log my GitHub CLI into that one org where someone let me play around with enterprise features for a while
# (Note:  only works because at the time of running this script, 
# the GitHub CLI was only logged into 2 accounts, total, including the one where this repo was published.)
$current_gh_repo_owner = (gh repo view --json 'owner' --jq '.owner.login')
$all_available_gh_usernames = gh auth status --json 'hosts' --jq '[.hosts."github.com"[].login]' | ConvertFrom-Json
$first_listed_non_current_repo_owner_gh_user = $all_available_gh_usernames | Where-Object { $_ -ne $current_gh_repo_owner } | Select-Object -First 1
$gh_cli_logged_in_user = (gh auth status --active --json 'hosts' --jq '.hosts."github.com"[0].login')
If ($gh_cli_logged_in_user -ne $first_listed_non_current_repo_owner_gh_user) {
    gh auth switch --user $first_listed_non_current_repo_owner_gh_user
}

Push-Location("$PsScriptRoot/AA-tf")

terraform apply `
    -var workload_nickname="$([Environment]::GetEnvironmentVariable('DEMOS_my_workload_nickname', 'User'))" `
    -var gh_org_name="$([Environment]::GetEnvironmentVariable('DEMOS_my_gh_org_name', 'User'))" `
    -input=false `
    -auto-approve

Pop-Location