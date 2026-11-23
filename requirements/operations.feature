Feature: Operations
  The services start only with the settings they need and prepare their own storage.

  Rule: A service will not start without its signing secret

    @accounts
    Scenario: The account service refuses to start without a signing secret
      When the account service starts without a signing secret
      Then it refuses to start because "JWT_SECRET_KEY environment variable is not set"

    @accounts
    Scenario: The account service starts with a signing secret
      When the account service starts with a signing secret
      Then it starts

    Scenario: The content service refuses to start without a signing secret
      When the content service starts without a signing secret
      Then it refuses to start because "JWT_SECRET_KEY environment variable is not set"

    Scenario: The content service starts with a signing secret
      When the content service starts with a signing secret
      Then it starts

  Rule: The content service starts only with a known AI engine

    Scenario: An unknown AI engine stops the start
      When the content service starts with the AI engine "mystery-ai"
      Then it refuses to start because "Unknown AI engine 'mystery-ai'"

    Scenario: Claude Code is accepted as the AI engine
      When the content service starts with the AI engine "claude-code"
      Then it starts

  Rule: The session cookie is secure unless the setting turns it off

    @accounts
    Scenario: The session cookie is secure by default
      When the account service starts without a cookie security setting
      Then the session cookie is sent only over HTTPS

    @accounts
    Scenario: The session cookie can be allowed over plain HTTP
      When the account service starts with the cookie security setting "false"
      Then the session cookie is also sent over plain HTTP

    @accounts
    Scenario: An unreadable cookie security setting stops the start
      When the account service starts with the cookie security setting "maybe"
      Then it refuses to start because "REFRESH_COOKIE_SECURE must be one of 1, true, yes, on, 0, false, no, off"

  Rule: Each service creates its database on first start

    @accounts
    Scenario: A missing account database is created
      Given the Postgres server has no account database
      When the account migrations start against Postgres
      Then the account database is created

    @accounts
    Scenario: An existing account database is kept
      Given the Postgres server already has the account database
      When the account migrations start against Postgres
      Then no database is created

    @accounts
    Scenario: A non-Postgres account database needs no creating
      When the account migrations start against SQLite
      Then the Postgres server is never contacted

    Scenario: A missing content database is created
      Given the Postgres server has no content database
      When the content migrations start against Postgres
      Then the content database is created

    Scenario: An existing content database is kept
      Given the Postgres server already has the content database
      When the content migrations start against Postgres
      Then no content database is created

    Scenario: A non-Postgres content database needs no creating
      When the content migrations start against SQLite
      Then the content Postgres server is never contacted

  Rule: My content is kept in the content database

    Scenario: A folder I create is stored in the content database
      Given the content service uses its own database
      When I create the folder "Biology" in home
      Then the content database holds the folder "Biology"

    Scenario: Home is stored in the content database the first time I open it
      Given the content service uses its own database
      When I open home
      Then the content database holds my home folder
