# Contribute to the Branch Protection Enforcer App

* [Prerequisites](#prerequisites)
* [Local Development Workflow](#local-development-workflow)

## Prerequisites

* [ruby](https://www.ruby-lang.org/en/)  _(2.7.3 or newer)_
* [node.js](https://nodejs.org/en/)  _(v16.4.2 or newer)_
* [rbenv](https://github.com/rbenv/rbenv)  _(optional)_
* [nvm](https://github.com/nvm-sh/nvm)  _(optional)_

[Back to the top](#contribute-to-the-branch-protection-enforcer-app)

## Local Development Workflow

Local development for the Branch Protection Enforcer App follows most of the ["Setting up your development environment to create a GitHub App" guide](https://docs.github.com/en/developers/apps/getting-started-with-apps/setting-up-your-development-environment-to-create-a-github-app) with the main difference being this is designed as an app installed for an organization.

1. **Setup Smee client for proxying GitHub App webhook events**

   1. Install Smee client

      ```shell
      $ npm install --global smee-client
      ```

   1. Start a new Smee channel

      ![Smee home page](docs/contributing/smee_home.png)
      ![Smee channel page](docs/contributing/smee_channel.png)

   1. Run Smee client for channel

      ```shell
      $ smee --path /event_handler --port 3000 -u https://smee.io/XXXXXX#XXXX#XXXX
      ```
   
1. **Register a new GitHub App**

   1. Navigate to the [Register new GitHub App](https://github.com/settings/apps/new)  _(from **New GitHub App** button on [GitHub > Developer Settings > GitHub Apps](https://github.com/settings/apps) screen)_

      ![List of developer GitHub Apps](docs/contributing/developer_github_apps.png)
      ![New developer GitHub App](docs/contributing/developer_github_new_app.png)

   1. Provide the following information:

      * **GitHub App name**<br />
        _Set this to something like "branch-protection-enforcer-dev-USERNAME"; allow you and others in your organization to develop simultaneously_

      * **Homepage URL**<br />
        _Set this to the Smee channel URL; https://smee.io/XXXXXX#XXXX#XXXX_

      * **Webhook URL**<br />
        _Set this to the Smee channel URL; https://smee.io/XXXXXX#XXXX#XXXX_

      * **Webhook secret**<br />
        _Set this to something random to ensure webhook events are likely coming from GitHub_

      * **Repository permissions**<br />
        _Select the following permissions for the GitHub App to request when installed_

        * **Administration**: Read & write
        * **Issues**: Read & write

      * **Subscribe to events**<br />
        _Select the following events for the GitHub App to receive when installed_

        * **Repositories**

      * **Where can this GitHub App be installed?**<br />
        _Set this to "Only on this account"_

      What this form would look like with some of the extraneous permissions removed:<br />
      ![Trimmed view of new GitHub App form with relevant fields](docs/contributing/developer_github_new_app_settings.png)

1. **Save your private key and App ID**

   With the newly created developer GitHub App, we need to generate the necessary private key along with the app ID for our developer environment to authenticate.<br />
   ![Recently created developer GitHub App](docs/contributing/developer_github_new_app_ready.png)

   Clicking link in header jumps down to the Private keys section<br />
   ![Generating private key triggers a file download containing private key](docs/contributing/developer_github_new_app_key.png)

1. **Prepare the `.env` runtime environment**

   1. Create `.env` file in root of repository based on `.env-example`

      ```shell
      $ cp .env-example .env
      ```

   1. Customize `.env` file based upon information from developer GitHub App information

      ```
      GITHUB_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
      ... file contents from generating private key ...
      -----END RSA PRIVATE KEY-----"
      GITHUB_APP_IDENTIFIER=#####
      GITHUB_WEBHOOK_SECRET=this is whatever random value you entered when creating developer GitHub App
      ```

1. **Start the server**

   1. Install dependencies

      ```shell
      $ gem install bundler
      $ bundle update --bundler
      $ bundle install
      ```

   1. Run service

      ```shell
      $ bundle exec ruby server.rb
      ```

1. **Install the app on your account**

   For development purposes, you should install the developer GitHub App on your personal GitHub organization
   ![Installing developer GitHub App on personal organization](docs/contributing/developer_github_app_install.png)

   Confirmation of the permissions we selected when we initially registered the developer GitHub App
   ![Confirmation of permissions being granted to installation](docs/contributing/developer_github_app_install_confirm.png)

1. **Create new repository and verify it works**

   ![Demo creating new repository](docs/contributing/demo_new_repo.png)
   ![Demo new repository issues](docs/contributing/demo_new_repo_issues.png)
   ![Demo new repository issue describing branch protection rule created](docs/demo_new_repo_issue.png)
   ![Demo new repository branch protection rule](docs/demo_new_repo_branch_protection.png)

[Back to the top](#contribute-to-the-branch-protection-enforcer-app)

## Resources

* [GitHub Actions Documentation](https://docs.github.com/en/actions)
  * [Building and testing Ruby](https://docs.github.com/en/actions/guides/building-and-testing-ruby)