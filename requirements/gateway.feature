Feature: Gateway
  The gateway in front of the cloud services protects them before any
  request reaches a service.

  Rule: An oversized or unmeasured upload is refused before it reaches a service

    @gateway
    Scenario: An upload declared over 100 MB is refused with 413
      When a content upload declaring 101 MB reaches the gateway
      Then the gateway refuses it with 413

    @gateway
    Scenario: A chunked upload without a length is refused with 411
      When a chunked content upload without a length reaches the gateway
      Then the gateway refuses it with 411

    @gateway
    Scenario: An upload of exactly 100 MB is passed on
      When a content upload declaring 100 MB reaches the gateway
      Then the gateway passes it on

    @gateway
    Scenario: A sign-up declared over 100 MB is refused with 413
      When a sign-up declaring 101 MB reaches the gateway
      Then the gateway refuses it with 413

  Rule: Sign-ins and costly generation are rate limited per client

    @gateway
    Scenario: Sign-in attempts are limited per client
      Then sign-in attempts are limited to 10 a minute per client

    @gateway
    Scenario: Generation requests are limited per client
      Then generation requests are limited to 30 a minute per client

    @gateway
    Scenario: Checking on a generation is not limited as a generation
      Then checking on a generation is not counted as a generation

  Rule: Preflight requests are answered at the gateway

    @gateway
    Scenario: A preflight to a protected route is answered with 204
      When a preflight request reaches a protected route
      Then the gateway answers it with 204

    @gateway
    Scenario: A preflight to a public route is answered with 204
      When a preflight request reaches a public route
      Then the gateway answers it with 204
