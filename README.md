This is an example GitHub App that adds a label to all new issues opened in a repository. You can follow the "[Using the GitHub API in your app](https://developer.github.com/apps/quickstart-guides/using-the-github-api-in-your-app/)" quickstart guide on developer.github.com to learn how to build the app code in `server.rb`.

This project listens for webhook events and uses the Octokit.rb library to make REST API calls. This example project consists of two different servers:
* `template_server.rb` (GitHub App template code)
* `server.rb` (completed project)

To learn how to set up a template GitHub App, follow the "[Setting up your development environment](https://developer.github.com/apps/quickstart-guides/setting-up-your-development-environment/)" quickstart guide on developer.github.com.

## Install

To run the code, make sure you have [Bundler](https://bundler.io/) installed; then enter `bundle install` on the command line.

## Set environment variables

1. Create a copy of the `.env-example` file called `.env`.
2. Add your GitHub App's private key, app ID, and webhook secret to the `.env` file.

## Run the server

1. Run `ruby template_server.rb` or `ruby server.rb` on the command line.
1. View the default Sinatra app at `localhost:3000`.
