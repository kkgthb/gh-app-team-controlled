Getting a GitHub Actions workflow attached to Repo A to read from or write to, Repo B, is a real pain.

This is me working out the kinks of all of the config required to make it happen.

3/20/2026

---

Here's the idea of the manual steps it could potentially replace walking admins through:

> I would like to request the following configuration changes to the "COMPANY_ORG_NAME" GitHub Enterprise Cloud organization.
>
> ## CONFIG 1 OF 5:  a new org-wide GitHub App
> 
> For naming inspiration, please see an unrelated but similar-idea existing GitHub App that has been installed into a repository called "repoY."  I believe it should show up under `https://github.com/COMPANY_ORG_NAME/repoY/settings/installations`.  And then you should be able to see additional details about the app itself by finding and clicking it within the list available at `https://github.com/organizations/COMPANY_ORG_NAME/settings/apps/`.
> 
> Once you have picked a reasonable-sounding name, you can go to `https://github.com/organizations/COMPANY_ORG_NAME/settings/apps/new` to create the new org-wide GitHub App.
> 
> Here are the settings it should have:
> 
> * **GitHub App Name:**  (as picked per your judgment)
> * **Description:**  (as picked per your judgment, hopefully the role model has some inspiration)
> * **Homepage URL:**  (it doesn't really need one, so hopefully the role model has some inspiration for a placeholder; perhaps just use the company's home page if you do not see anything else that makes any more sense)
> * **Checkboxes:**  UNCHECK them all, please
> * **Text fields:**  leave them all BLANK, please
> * **Repository Permissions:**  Contents -> `Read-only` (this will also flip Metadata to `Read-only`, and that's fine)
> * **Organization/Account permissions:**  (skip; leave all as they are at No access)
> * **Where can this GitHub App be installed:**  Only on this account
> 
> Then click the "Create GitHub App" button
> 
> ## CONFIG 2 OF 5:  a new private key for the new GitHub App
> 
> As soon as you click "Create GitHub App" above, you will be redirected to the settings page for the app you just created.  It will have a URL something like `https://github.com/organizations/COMPANY_ORG_NAME/settings/apps/SOME_VALUE_HERE`.
> 
> At the top of the page, there will be a yellow-background toast alert reading "Registration successful.  You must generate a private key in order to install your GitHub App."  You can ignore that for now, it's not true, within a single organization.  You can come back to it later, because it's a bit finicky and it's good to be dedicated to the task.
> 
> ## CONFIG 3 OF 5:  install the new GitHub App into a specific repository within the "COMPANY_ORG_NAME" org
> 
> In the left nav-menu of the new GitHub App's settings page, there is an "Install App" option.  It leads to 
`https://github.com/organizations/COMPANY_ORG_NAME/settings/apps/SOME_VALUE_HERE/installations`.  Click it.
> 
> Under "choose an account to install (YOUR APP NAME HERE) on, click the "Install" button to the right of "`COMPANY_ORG_NAME`."  (It leads to `https://github.com/apps/SOME_VALUE_HERE/installations/new/permissions?target_id=THE_ORG_ID_FOR_COMPANY_ORG_NAME&target_type=Organization`.)
> 
> In the splash screen:
> 
> 1. Change the radio selector from "All repositories" to "**Only select repositories**."
> 2. In the "Select repositories" picklist that appears below the second radio option, choose "`COMPANY_ORG_NAME/repoB`".
> 3. Click the "Install" button.
> 
> This will redirect you to a URL of the format `https://github.com/organizations/COMPANY_ORG_NAME/settings/installations/SOME_INTEGER_HERE`.  You will never need to look at it again unless you need to tear down this whole GitHub App.  In which case, you can easily find it and uninstall it at a later date from `https://github.com/organizations/COMPANY_ORG_NAME/settings/installations/`.
> 
> 
> ## CONFIG 4 OF 5:  generate a private key for "becoming" the GitHub App
> 
> Back in the new GitHub App's settings page, the yellow toast has probably disappeared.  That's okay -- the "generate a private key" link just jumped down the page to `https://github.com/organizations/COMPANY_ORG_NAME/settings/apps/SOME_VALUE_HERE#private-key`, which you can reach by simply scrolling down the GitHub App's settings page until you reach the "Generate a private key" section.
> 
> Please perform the following steps:
> 
> 1. Make sure that you are ready to be prompted by your browser to download a file, or know where your downloads go if you have them set to automatically download them to a certain folder.
> 2. Click the "Generate a private key" button.
> 3. Accept a download of the file named "`SOME_VALUE_HERE.SOME_DATESTAMP_HERE.private-key.pem`" onto your hard drive.  Anywhere will do; you'll be deleting it when all of the configuration steps are done.
> 
> Note:  the "Generate a private key" button will remain in this part of the GitHub App's settings page, though it will be less prominent and will be placed above the list of existing private keys attached to the GitHub App.  If you ever need to "rotate" a compromised private key, you will more or less start over in this "CONFIG 4" part of the process as if you had never generated one in the first place, and when you have put the new `.pem` file's value where it belongs toward the end of all of these "config" steps, it will be safe to click the "DELETE" button to the right of the old compromised key (as found in the GitHub App's settings page's list of attached private keys).
> 
> ## CONFIG 5 OF 5:  create a new org-wide GitHub Actions Secret and allow the client repo to see its value
> 
> Go to `https://github.com/organizations/COMPANY_ORG_NAME/settings/secrets/actions/new` to create a new org-wide GitHub Actions Secret.
> 
> 1. **Name:**  `DEPTABBREVHERE_REPO_A_READS_DEPTABBREVHERE_REPO_B_SSH`
> 2. **Value:**  Open up the `.pem` file you downloaded in a plaintext editor like Notepad, copy it to your clipboard (e sure to use "Ctrl+A" to select the contents, lest weird issues about the trailing line break being or not being present mess things up), and paste it into "Value."
> 3. **Repository access:**  IMPORTANT:  change this from "Public repositories" to "**Selected repositories**."
> 4. **Click the gear icon** to the right of "0 selected repositories" and click the checkbox next to "`repoA`."
> 5. Click the "Add secret" button.
> 
> Proceed to the validation step below
> 
> ## VALIDATION STEP:  check if the config works
> 
> Before deleting the `.pem` file off of your hard drive, please partner with me _(the opener of this request)_ to validate whether the config works.
> 
> Sometimes, the copy-paste goes wonky and a bit of hands-on troubleshooting is necessary.
