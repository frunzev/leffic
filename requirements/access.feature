Feature: Access
  Only the signed-in owner reaches their content.

  Rule: Without a sign-in nothing is reachable

    Scenario: Opening home without signing in is refused
      When someone opens home without signing in
      Then they are refused as not signed in

    Scenario: A forged sign-in is refused
      When someone opens home with a forged sign-in
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

    Scenario: Another user cannot review my cards
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When another user asks for the cards due in the deck "Cells"
      Then they are told "Deck does not exist!"
