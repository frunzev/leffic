Feature: Accounts
  Sign up, sign in and look after my account and AI keys.

  Rule: Signing up signs me in

    @accounts
    Scenario: A new account is signed in at once
      When I sign up as "learner" with "learner@example.com"
      Then I am signed in as "learner"

    @accounts
    Scenario: A new account starts with the system theme
      When I sign up as "learner" with "learner@example.com"
      Then my account uses the "system" theme

  Rule: Logging in needs the right password

    @accounts
    Scenario: A wrong password is refused
      Given someone signed up as "learner" with "learner@example.com"
      When I log in as "learner@example.com" with a wrong password
      Then I am told "Incorrect password"

    @accounts
    Scenario: The right password logs me in
      Given someone signed up as "learner" with "learner@example.com"
      When I log in as "learner@example.com" with my password
      Then I am signed in as "learner"

    @accounts
    Scenario: An unknown email is refused
      When I log in as "nobody@example.com" with my password
      Then I am told "Incorrect email"

  Rule: A session renews itself until I log out

    @accounts
    Scenario: Renewing a session gives a fresh access token
      Given I signed up as "learner" with "learner@example.com"
      When I renew my session
      Then I get a fresh access token

    @accounts
    Scenario: Logging out ends the session
      Given I signed up as "learner" with "learner@example.com"
      When I log out
      And I renew my session
      Then I am told "Missing refresh token"

  Rule: Deleting my account needs my password and removes everything I own

    @accounts
    Scenario: A deleted account can no longer log in
      Given I signed up as "learner" with "learner@example.com"
      When I delete my account
      Then logging in as "learner@example.com" with the old password is refused

    @accounts
    Scenario: A wrong password keeps the account
      Given I signed up as "learner" with "learner@example.com"
      When I delete my account with a wrong password
      Then I am told "That password is not right."
      And logging in as "learner@example.com" with my password works

    @accounts
    Scenario: A deleted account is announced so its content is removed
      Given I signed up as "learner" with "learner@example.com"
      When I delete my account
      Then my deletion is announced


    Scenario: My folders and their content are removed
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      When my account is deleted
      Then the folder "Biology" does not exist
      And the deck "Cells" does not exist

    Scenario: My stored files are removed from disk
      Given I upload the PDF "cells.pdf" saying "Cells divide" into home
      When my account is deleted
      Then nothing is left on disk

    Scenario: Another user's content stays
      Given another user has the folder "Secret"
      When my account is deleted
      Then another user still has the folder "Secret"

  Rule: A username or an email belongs to one account only

    @accounts
    Scenario: A taken username is refused
      Given someone signed up as "learner" with "learner@example.com"
      When I sign up as "learner" with "other@example.com"
      Then I am told the code "username_registered"

    @accounts
    Scenario: A taken email is refused
      Given someone signed up as "learner" with "learner@example.com"
      When I sign up as "scholar" with "learner@example.com"
      Then I am told the code "email_registered"

  Rule: After a password change only the new password logs me in

    @accounts
    Scenario: The old password stops working
      Given I signed up as "learner" with "learner@example.com"
      When I change my password
      Then logging in as "learner@example.com" with the old password is refused
      And logging in as "learner@example.com" with the new password works

    @accounts
    Scenario: A wrong current password is refused
      Given I signed up as "learner" with "learner@example.com"
      When I change my password giving a wrong current password
      Then I am told "That password is not right."

  Rule: A new password that is too short is refused

    @accounts
    Scenario: A three-letter password is refused
      Given I signed up as "learner" with "learner@example.com"
      When I change my password to "abc"
      Then I am told "The new password is too short."

    @accounts
    Scenario: The old password keeps working after a refused change
      Given I signed up as "learner" with "learner@example.com"
      When I change my password to "abc"
      Then logging in as "learner@example.com" with my password works

  Rule: I can change my username

    @accounts
    Scenario: A new username is shown on my account
      Given I signed up as "learner" with "learner@example.com"
      When I change my username to "scholar"
      Then I am signed in as "scholar"

    @accounts
    Scenario: My old username becomes free
      Given I signed up as "learner" with "learner@example.com"
      When I change my username to "scholar"
      And someone signs up as "learner" with "other@example.com"
      Then the sign-up works

  Rule: A blank or taken username is refused

    @accounts
    Scenario: A blank username is refused
      Given I signed up as "learner" with "learner@example.com"
      When I change my username to " "
      Then I am told "Username cannot be blank."

    @accounts
    Scenario: A taken username is refused when changing it
      Given someone signed up as "scholar" with "scholar@example.com"
      And I signed up as "learner" with "learner@example.com"
      When I change my username to "scholar"
      Then I am told "That username is taken."

  Rule: My AI provider key is kept but never shown back

    @accounts
    Scenario: A saved OpenAI key shows only its last characters
      Given I signed up as "learner" with "learner@example.com"
      When I save the OpenAI key "sk-live-000000000000000007Xa2"
      Then my saved keys show "7Xa2" but never the key itself

    @accounts
    Scenario: A saved Gemini key shows only its last characters
      Given I signed up as "learner" with "learner@example.com"
      When I save the Gemini key "gm-live-22222222222222225Kc9"
      Then my saved keys show "5Kc9" but never the key itself

    @ui
    Scenario: The app shows a saved OpenAI key only masked
      Given the Keychain holds the OpenAI key "sk-live-000000000000000007Xa2"
      When I open Settings in the app
      Then the app shows the OpenAI key "sk-live-000000000000000007Xa2" only masked

  Rule: A saved key opens only with my password

    @accounts
    Scenario: My password opens my key
      Given I signed up as "learner" with "learner@example.com"
      And I saved the OpenAI key "sk-live-000000000000000007Xa2"
      When I open my OpenAI key with my password
      Then I get the key "sk-live-000000000000000007Xa2"

    @accounts
    Scenario: A wrong password does not open my key
      Given I signed up as "learner" with "learner@example.com"
      And I saved the OpenAI key "sk-live-000000000000000007Xa2"
      When I open my OpenAI key with a wrong password
      Then I am told "That password is not right."

  Rule: A key saved before a password change asks to be saved again

    @accounts
    Scenario: The new password cannot open an old key
      Given I signed up as "learner" with "learner@example.com"
      And I saved the OpenAI key "sk-live-000000000000000007Xa2"
      And I changed my password
      When I open my OpenAI key with my new password
      Then I am told "This key was sealed with an earlier password."

    @accounts
    Scenario: Saving the key again opens it
      Given I signed up as "learner" with "learner@example.com"
      And I saved the OpenAI key "sk-live-000000000000000007Xa2"
      And I changed my password
      And I saved the OpenAI key "sk-live-000000000000000007Xa2" again with my new password
      When I open my OpenAI key with my new password
      Then I get the key "sk-live-000000000000000007Xa2"

  Rule: I can remove a saved key

    @accounts
    Scenario: A removed key is gone
      Given I signed up as "learner" with "learner@example.com"
      And I saved the OpenAI key "sk-live-000000000000000007Xa2"
      When I remove my OpenAI key
      Then I have no saved keys

    @accounts
    Scenario: Removing a key I never saved is refused
      Given I signed up as "learner" with "learner@example.com"
      When I remove my Gemini key
      Then I am told "No key is saved for that provider."

  Rule: A key can carry a monthly spending limit

    @accounts
    Scenario: A limit is kept with the key
      Given I signed up as "learner" with "learner@example.com"
      When I save the OpenAI key "sk-live-000000000000000007Xa2" with a monthly limit of 500 cents
      Then my OpenAI key has a monthly limit of 500 cents

    @accounts
    Scenario: A key saved without a limit has none
      Given I signed up as "learner" with "learner@example.com"
      When I save the OpenAI key "sk-live-000000000000000007Xa2"
      Then my OpenAI key has no monthly limit

  Rule: My theme is remembered

    @accounts
    Scenario: A chosen theme stays on my account
      Given I signed up as "learner" with "learner@example.com"
      When I choose the "dark" theme
      Then my account uses the "dark" theme

    @accounts
    Scenario: An unknown theme is refused
      Given I signed up as "learner" with "learner@example.com"
      When I choose the "purple" theme
      Then my account uses the "system" theme
