Feature: Flashcards
  Review cards exactly when they are about to be forgotten.

  Rule: A card I never reviewed is due right away

    Scenario: A new card is in today's review
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I ask for the cards due in the deck "Cells"
      Then I get the card "What is a cell?"

    Scenario: Every new card in a deck is due
      Given I have the deck "Cells" in home with the card "What is a cell?"
      And the deck "Cells" also has the card "What is a neuron?"
      When I ask for the cards due in the deck "Cells"
      Then I get the card "What is a cell?"
      And I get the card "What is a neuron?"

  Rule: Rating a card schedules its next review

    Scenario: A card I rate Easy leaves today's review
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I rate the card "What is a cell?" as "Easy"
      Then the deck "Cells" has no cards due today

    Scenario: A card I rate Easy is put off for at least a day
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I rate the card "What is a cell?" as "Easy"
      Then the card is put off for at least 1 day


    @ui
    Scenario: Rating the last card Good sends 3 and ends the review
      Given the backend has the deck "Cells" with the due card "What is DNA?" answered "A molecule"
      When I review the deck "Cells" in the app
      And I show the answer
      And I rate the card "Good"
      Then the backend received the rating 3
      And the app shows "You're done for today"

    @ui
    Scenario: Rating the last card Again sends 1 and ends the review
      Given the backend has the deck "Cells" with the due card "What is DNA?" answered "A molecule"
      When I review the deck "Cells" in the app
      And I show the answer
      And I rate the card "Again"
      Then the backend received the rating 1
      And the app shows "You're done for today"

  Rule: Only my own readable cards can be rated

    Scenario: Asking when an unreadable card comes back is refused
      When I ask when an unreadable card comes back for each rating
      Then I am told "That card cannot be read."

    Scenario: Another user cannot rate my card
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When another user rates the card "What is a cell?" as "Good"
      Then they are told "Flashcard does not exist!"

    Scenario: Asking for due cards without a folder is refused
      When I ask for the cards due without naming a folder
      Then I am told "Folder does not exist!"

    Scenario: A folder without cards has no review counts
      Given I have the folder "Biology" in home
      When I ask how many cards are due in "Biology"
      Then I am told "No flashcards!"

  Rule: Each rating shows when the card comes back

    Scenario: A harder rating never brings a new card back later
      When I ask when a new card comes back for each rating
      Then "Again" comes back no later than "Hard"
      And "Hard" comes back no later than "Good"
      And "Good" comes back no later than "Easy"

    Scenario: A harder rating never brings a reviewed card back later
      Given I have the deck "Cells" in home with the card "What is a cell?"
      And I rated the card "What is a cell?" as "Easy"
      When I ask when the card "What is a cell?" comes back for each rating
      Then "Again" comes back no later than "Hard"
      And "Hard" comes back no later than "Good"
      And "Good" comes back no later than "Easy"


    @ui
    Scenario: A rating minutes away is labelled in minutes
      Given the backend has the deck "Cells" with the due card "What is DNA?" answered "A molecule"
      And the backend brings the card back in 900 seconds for "Good"
      When I review the deck "Cells" in the app
      And I show the answer
      Then the app shows "A molecule"
      And the "Good" button says "15 min"

    @ui
    Scenario: A rating days away is labelled in days
      Given the backend has the deck "Cells" with the due card "What is DNA?" answered "A molecule"
      And the backend brings the card back in 259200 seconds for "Easy"
      When I review the deck "Cells" in the app
      And I show the answer
      Then the "Easy" button says "3 days"

  Rule: Mixed review covers a folder and every folder beneath it

    Scenario: A card in a subfolder is due in its parent
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      When I ask for the cards due in home
      Then I get the card "What is a cell?"

    Scenario: A card two levels down is due in the top folder
      Given I have the folder "Biology" in home
      And I have the folder "Cells" in "Biology"
      And I have the deck "Neurons" in "Cells" with the card "What is a neuron?"
      When I ask for the cards due in the folder "Biology"
      Then I get the card "What is a neuron?"

    Scenario: A card in a sibling folder is left out
      Given I have the folder "Biology" in home
      And I have the folder "Chemistry" in home
      And I have the deck "Atoms" in "Chemistry" with the card "What is an atom?"
      When I ask for the cards due in the folder "Biology"
      Then I get no cards

  Rule: A folder counts the cards due across every folder beneath it

    Scenario: Cards in subfolders count toward the folder
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      And I have the deck "Atoms" in home with the card "What is an atom?"
      When I ask how many cards are due in home
      Then home has 2 cards due and 0 done

    Scenario: A card I rated Easy counts as done
      Given I have the deck "Cells" in home with the card "What is a cell?"
      And I rated the card "What is a cell?" as "Easy"
      When I ask how many cards are due in home
      Then home has 0 cards due and 1 done

  Rule: I can edit a card

    Scenario: An edited card shows its new question
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I change the card "What is a cell?" to "What is a neuron?"
      Then the deck "Cells" has the card "What is a neuron?"

    Scenario: An edited card shows its new answer
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I change the answer of "What is a cell?" to "The unit of life"
      Then the card "What is a cell?" answers "The unit of life"

  Rule: I can delete a card

    Scenario: A deleted card leaves the review
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I delete the card "What is a cell?"
      Then the deck "Cells" has no cards due today

    Scenario: Deleting one card keeps the others
      Given I have the deck "Cells" in home with the card "What is a cell?"
      And the deck "Cells" also has the card "What is a neuron?"
      When I delete the card "What is a cell?"
      Then the deck "Cells" has the card "What is a neuron?"
