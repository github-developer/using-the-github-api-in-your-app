require 'sinatra'
require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object
require 'logger'      # Logs debug statements

set :port, 3000
set :bind, '0.0.0.0'

class GHAapp < Sinatra::Application

  # Converts the newlines. Expects that the private key has been set as an
  # environment variable in PEM format.
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))

  # Your registered app must have a secret set. The secret is used to verify
  # that webhooks are sent by GitHub.
  WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']

  # The GitHub App's identifier (type integer) set when registering an app.
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  # Turn on Sinatra's verbose logging during development
  configure :development do
    set :logging, Logger::DEBUG
  end


  # Executed before each request to the `/event_handler` route
  before '/event_handler' do
    get_payload_request(request)
    verify_webhook_signature
    authenticate_app
    # Authenticate the app installation in order to run API operations
    authenticate_installation(@payload)
  end


  post '/event_handler' do

    case request.env['HTTP_X_GITHUB_EVENT']
    when 'repository'
      if @payload['action'] === 'created'
        handle_repository_created_event(@payload)
      end
    end

    200 # success status
  end


  helpers do

    # When a repository is created, create branch protection rule and document it
    def handle_repository_created_event(payload)
      repo = payload['repository']['full_name']
      default_branch = 'main' # normally would be payload['repository']['default_branch'] but webhook bug says default is 'master' when it is 'main'
      branch_protection = @installation_client.branch_protection(repo, default_branch, {
        :accept => Octokit::Preview::PREVIEW_TYPES[:branch_protection],
      })

      if branch_protection.nil?
        @installation_client.protect_branch(repo, default_branch, {
          :accept => Octokit::Preview::PREVIEW_TYPES[:branch_protection],
          :enforce_admins => true,
          :required_pull_request_reviews => {
            :dismiss_stale_reviews => true,
            :require_code_owner_reviews => true,
            :required_approving_review_count => 2,
          },
        })

        branch_protection = @installation_client.branch_protection(repo, default_branch, {
          :accept => Octokit::Preview::PREVIEW_TYPES[:branch_protection],
        })

        body = <<~EOB
          Hey @#{payload['sender']['login']},
          
          Congrats on starting the next big thing! :clap: :tada: :trophy:  In order to help, a branch protection rule with the following settings were created for the **#{default_branch}** branch.

          ---

          :#{branch_protection[:required_pull_request_reviews] ? 'white_check_mark' : 'black_square_button'}: **Require pull request reviews before merging**
          _When enabled, all commits must be made to a non-protected branch and submitted via a pull request with the required number of approving reviews and no changes requested before it can be merged into a branch that matches this rule._

          - **Required approving reviews**: #{branch_protection[:required_pull_request_reviews] ? branch_protection[:required_pull_request_reviews][:required_approving_review_count] : ''}

          - :#{branch_protection[:required_pull_request_reviews] && branch_protection[:required_pull_request_reviews][:dismiss_stale_reviews] ? 'white_check_mark' : 'black_square_button'}: **Dismiss stale pull request approvals when new commits are pushed**
            _New reviewable commits pushed to a matching branch will dismiss pull request review approvals._

          - :#{branch_protection[:required_pull_request_reviews] && branch_protection[:required_pull_request_reviews][:require_code_owner_reviews] ? 'white_check_mark' : 'black_square_button'}: **Require review from Code Owners**
            _Require an approved review in pull requests including files with a designated code owner._

          :#{branch_protection[:required_status_checks] ? 'white_check_mark' : 'black_square_button'}: **Require status checks to pass before merging**
          _Choose which status checks must pass before branches can be merged into a branch that matches this rule. When enabled, commits must first be pushed to another branch, then merged or pushed directly to a branch that matches this rule after status checks have passed._

          - :#{branch_protection[:required_status_checks] && branch_protection[:required_status_checks][:strict] ? 'white_check_mark' : 'black_square_button'}: **Require branches to be up to date before merging**
            _This ensures pull requests targeting a matching branch have been tested with the latest code. This setting will not take effect unless at least one status check is enabled (see below)._

          :#{branch_protection[:required_conversation_resolution][:enabled] ? 'white_check_mark' : 'black_square_button'}: **Require conversation resolution before merging**
          _When enabled, all conversations on code must be resolved before a pull request can be merged into a branch that matches this rule._

          :#{branch_protection[:required_linear_history][:enabled] ? 'white_check_mark' : 'black_square_button'}: **Require linear history**
          _Prevent merge commits from being pushed to matching branches._

          :#{branch_protection[:enforce_admins][:enabled] ? 'white_check_mark' : 'black_square_button'}: **Include administrators**
          _Enforce all configured restrictions above for administrators._

          :#{branch_protection[:allow_force_pushes][:enabled] ? 'white_check_mark' : 'black_square_button'}: **Allow force pushes**
          _Permit force pushes for all users with push access._

          :#{branch_protection[:allow_deletions][:enabled] ? 'white_check_mark' : 'black_square_button'}: **Allow deletions**
          _Allow users with push access to delete matching branches._
        EOB

        issue = @installation_client.create_issue(repo, "Setup branch protection for #{default_branch}", body)
        @installation_client.close_issue(repo, issue.number)
      end
    end

    # Saves the raw payload and converts the payload to JSON format
    def get_payload_request(request)
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        fail  "Invalid JSON (#{e}): #{@payload_raw}"
      end
    end

    # Instantiate an Octokit client authenticated as a GitHub App.
    # GitHub App authentication requires that you construct a
    # JWT (https://jwt.io/introduction/) signed with the app's private key,
    # so GitHub can be sure that it came from the app and was not altered by
    # a malicious third party.
    def authenticate_app
      payload = {
          # The time that this JWT was issued, _i.e._ now.
          iat: Time.now.to_i,

          # JWT expiration time (10 minute maximum)
          exp: Time.now.to_i + (10 * 60),

          # Your GitHub App's identifier number
          iss: APP_IDENTIFIER
      }
      logger.debug "JWT payload: #{payload}"

      # Cryptographically sign the JWT.
      jwt = JWT.encode(payload, PRIVATE_KEY, 'RS256')

      # Create the Octokit client, using the JWT as the auth token.
      @app_client ||= Octokit::Client.new(bearer_token: jwt)
    end

    # Instantiate an Octokit client, authenticated as an installation of a
    # GitHub App, to run API operations.
    def authenticate_installation(payload)
      logger.warn "Delivery #{request.env['HTTP_X_GITHUB_DELIVERY']} missing installation payload" unless payload.include? 'installation'
      @installation_id = payload['installation']['id']
      @installation_token = @app_client.create_app_installation_access_token(@installation_id)[:token]
      @installation_client = Octokit::Client.new(bearer_token: @installation_token)
    end

    # Check X-Hub-Signature to confirm that this webhook was generated by
    # GitHub, and not a malicious third party.
    #
    # GitHub uses the WEBHOOK_SECRET, registered to the GitHub App, to
    # create the hash signature sent in the `X-HUB-Signature` header of each
    # webhook. This code computes the expected hash signature and compares it to
    # the signature sent in the `X-HUB-Signature` header. If they don't match,
    # this request is an attack, and you should reject it. GitHub uses the HMAC
    # hexdigest to compute the signature. The `X-HUB-Signature` looks something
    # like this: "sha1=123456".
    # See https://developer.github.com/webhooks/securing/ for details.
    def verify_webhook_signature
      their_signature_header = request.env['HTTP_X_HUB_SIGNATURE'] || 'sha1='
      method, their_digest = their_signature_header.split('=')
      our_digest = OpenSSL::HMAC.hexdigest(method, WEBHOOK_SECRET, @payload_raw)
      halt 401 unless their_digest == our_digest

      # The X-GITHUB-EVENT header provides the name of the event.
      # The action value indicates the which action triggered the event.
      logger.debug "---- received event #{request.env['HTTP_X_GITHUB_EVENT']}"
      logger.debug "----    action #{@payload['action']}" unless @payload['action'].nil?
    end

  end

  # Finally some logic to let us run this server directly from the command line,
  # or with Rack. Don't worry too much about this code. But, for the curious:
  # $0 is the executed file
  # __FILE__ is the current file
  # If they are the same—that is, we are running this file directly, call the
  # Sinatra run method
  run! if __FILE__ == $0
end
