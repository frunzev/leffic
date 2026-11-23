Feature: Access
  Only the signed-in owner reaches their content.

  Rule: Without a sign-in nothing is reachable

    Scenario: Opening home without signing in is refused
      When someone opens home without signing in
      Then they are refused as not signed in

    Scenario: A forged sign-in is refused
      When someone opens home with a forged sign-in
      Then they are refused as not signed in

    Scenario: A sign-in without the bearer scheme is refused
      When someone opens home with a sign-in lacking the bearer scheme
      Then they are refused as not signed in

    Scenario: A sign-in that names no user is refused
      When someone opens home with a sign-in that names no user
      Then they are refused as not signed in

    Scenario: A sign-in that names a malformed user is refused
      When someone opens home with a sign-in that names a malformed user
      Then they are refused as not signed in

    @accounts
    Scenario: My account cannot be opened without a sign-in
      When someone opens an account without signing in
      Then they are refused as not signed in

    @accounts
    Scenario: My account cannot be opened with a forged sign-in
      When someone opens an account with a forged sign-in
      Then they are refused as not signed in

    @accounts
    Scenario: My account cannot be opened without the bearer scheme
      When someone opens an account with a sign-in lacking the bearer scheme
      Then they are refused as not signed in

    @accounts
    Scenario: My account cannot be opened with a sign-in that names no user
      When someone opens an account with a sign-in that names no user
      Then they are refused as not signed in

    @accounts
    Scenario: My account cannot be opened with a sign-in that names a malformed user
      When someone opens an account with a sign-in that names a malformed user
      Then they are refused as not signed in

    @gateway
    Scenario: The gateway refuses a content request without a sign-in
      When a content request reaches the gateway without a sign-in
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway refuses a forged sign-in
      When a content request reaches the gateway with a forged sign-in
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway refuses an expired sign-in
      When a content request reaches the gateway with an expired sign-in
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway passes a valid sign-in on
      When a content request reaches the gateway with a valid sign-in
      Then the gateway passes it on

    @gateway
    Scenario: The gateway passes a sign-in that never expires
      When a content request reaches the gateway with a sign-in that never expires
      Then the gateway passes it on

    @gateway
    Scenario: The gateway refuses a sign-in whose claims cannot be read
      When a content request reaches the gateway with a sign-in whose claims cannot be read
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway refuses a sign-in that is not a bearer sign-in
      When a content request reaches the gateway with a sign-in that is not a bearer sign-in
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway refuses a sign-in with a cut-short signature
      When a content request reaches the gateway with a cut-short signature
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway refuses a sign-in token of a single part
      When a content request reaches the gateway with a sign-in token of a single part
      Then the gateway refuses it with 401

    @gateway
    Scenario: The gateway without a signing secret refuses every sign-in
      When a content request reaches a gateway that has no signing secret
      Then the gateway refuses it with 401
      And the gateway logs "JWT_SECRET_KEY is not set"

    @gateway
    Scenario: The gateway guards every content and account route
      Then the gateway guards "/api/content/" as a protected route
      And the gateway guards "/api/user/account" as a protected route
      And the gateway guards "~ ^/api/content/(upload-files|file|extract-text)$" as a protected route

  Rule: Signing up and logging in need no sign-in

    @gateway
    Scenario: The gateway passes a sign-up request without a sign-in
      When a sign-up request reaches the gateway without a sign-in
      Then the gateway passes it on

    @gateway
    Scenario: The gateway guards the user routes as public
      Then the gateway guards "/api/user/" as a public route

    @accounts
    Scenario: Signing up works without any earlier sign-in
      When I sign up as "learner" with "learner@example.com"
      Then the sign-up works

  Rule: Nobody else can reach my content

    Scenario: Another user cannot read my note
      Given I have the note "Cells" in home
      When another user opens the note "Cells"
      Then they are told "Note does not exist!"

    Scenario: Another user cannot delete my folder
      Given I have the folder "Biology" in home
      When another user deletes the folder "Biology"
      Then they are told "Folder does not exist!"

    Scenario: A malformed note id finds nothing
      When I open the note with the id "not-a-note-id"
      Then I am told "Note does not exist!"

    Scenario: Another user cannot import into my folder
      Given I have the folder "Biology" in home
      When another user imports "Cells divide." into the folder "Biology"
      Then they are told "Folder does not exist!"

    Scenario: Another user cannot review my cards
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When another user asks for the cards due in the deck "Cells"
      Then they are told "Deck does not exist!"
