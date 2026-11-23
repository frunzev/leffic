Feature: Ask
  Ask questions about my material and let Ask add cards.

  Rule: Ask answers with Claude Code when it is the chosen engine

    Scenario: A question gets Claude Code's answer
      Given Claude Code answers "Cells are the unit of life."
      When I ask "What is a cell?"
      Then I get the answer "Cells are the unit of life."

    Scenario: Claude Code sees the whole conversation
      Given Claude Code answers "Cells are the unit of life."
      When I ask two questions, "What is biology?" then "What is a cell?"
      Then Claude Code was shown "What is biology?" and "What is a cell?"

    @ui
    Scenario: Ask's answer appears in the conversation
      Given Ask answers every question with "Cells are the unit of life."
      When I ask "What is a cell?" in the app
      Then the app shows "What is a cell?"
      And the app shows "Cells are the unit of life."

    @ui
    Scenario: Settings shows where Claude Code was found
      Given Claude Code is installed at "/Users/someone/.local/bin/claude"
      When I open Settings in the app
      Then the app shows "Claude Code found at /Users/someone/.local/bin/claude"

  Rule: Ask uses OpenAI when that engine is chosen

    Scenario: OpenAI answers the question
      Given OpenAI is chosen and answers "Cells are the unit of life."
      When I ask "What is a cell?"
      Then I get the answer "Cells are the unit of life."

    Scenario: OpenAI without a key says how to set it up
      Given OpenAI is chosen without a key
      When I ask "What is a cell?"
      Then I am told "OpenAI is not set up. Add an OpenAI API key in Settings, or choose Claude Code there."

    Scenario: OpenAI that cannot be reached is explained
      Given OpenAI is chosen but cannot be reached
      When I ask "What is a cell?"
      Then I am told "The assistant is unavailable right now. Try again."

  Rule: Choosing another AI engine keeps me where I am

    @ui
    Scenario: Switching from Claude Code to OpenAI keeps me in Settings
      Given Settings has "Claude Code on this Mac" chosen as the engine
      When I choose "OpenAI" as the engine in Settings
      Then the app still shows Settings
      And Settings has "OpenAI" chosen as the engine
      And the backend was restarted in place once

    @ui
    Scenario: Saving an OpenAI key keeps me in Settings
      Given Settings has "Claude Code on this Mac" chosen as the engine
      When I save the OpenAI key "sk-live-000000000000000007Xa2" in Settings
      Then the app still shows Settings
      And the backend was restarted in place once

  Rule: Ask says clearly when the chosen Claude Code cannot answer

    Scenario: A missing Claude Code is reported
      Given Claude Code is not installed
      When I ask "What is a cell?"
      Then I am told "Claude Code did not answer. Check that it is installed and logged in."

    Scenario: A failing Claude Code is reported
      Given Claude Code fails
      When I ask "What is a cell?"
      Then I am told "Claude Code did not answer. Check that it is installed and logged in."

    @ui
    Scenario: An unavailable Claude Code is explained in the app
      Given Ask is unavailable with "Claude Code did not answer. Check that it is installed and logged in."
      When I ask "What is a cell?" in the app
      Then the app shows "Claude Code did not answer. Check that it is installed and logged in."

    @ui
    Scenario: Settings offers to install a missing Claude Code
      Given Claude Code is not on this Mac
      When I open Settings in the app
      Then the app shows "Not found on this Mac. The Ask chat runs on Claude Code."
      And the app offers "Install Claude Code"

  Rule: Ask can list my folders

    Scenario: Ask names my folders
      Given I have the folder "Biology" in home
      And Claude Code looks at my folders
      When I ask "Which folders do I have?"
      Then the answer mentions "Biology"

    Scenario: Ask never lists another user's folders
      Given another user has the folder "Secret"
      And Claude Code looks at my folders
      When I ask "Which folders do I have?"
      Then the answer does not mention "Secret"

    Scenario: Ask sees the decks and notes inside my folders
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      And I have the note "Mitosis" in "Biology"
      And Claude Code looks at my folders
      When I ask "Which folders do I have?"
      Then the answer mentions "Cells"
      And the answer mentions "Mitosis"

  Rule: Ask can read one of my notes

    Scenario: Ask reads my note
      Given I have the note "Cells" in home
      And Claude Code reads the note "Cells"
      When I ask "What does my note say?"
      Then the answer mentions "Cells are the unit of life."

    Scenario: Ask cannot read another user's note
      Given another user has the note "Secret"
      And Claude Code reads the note "Secret"
      When I ask "What does that note say?"
      Then the answer mentions "Note does not exist!"

  Rule: Ask adds a flashcard to a deck when I ask it to

    Scenario: Ask adds the card to my deck
      Given I have the deck "Cells" in home with the card "What is a cell?"
      And Claude Code adds the card "What is a neuron?" to the deck "Cells"
      When I ask "Add a card about neurons"
      Then the deck "Cells" has the card "What is a neuron?"

    Scenario: Ask cannot add a card to another user's deck
      Given another user has the deck "Secret"
      And Claude Code adds the card "What is a neuron?" to the deck "Secret"
      When I ask "Add a card about neurons"
      Then the answer mentions "Flashcard deck does not exist!"
