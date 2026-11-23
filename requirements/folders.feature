Feature: Folders
  Organise everything in nested folders under home.

  Rule: Home is my own root folder

    Scenario: Opening home for the first time shows an empty folder
      When I open home
      Then I see the folder "Home"
      And it is empty

    Scenario: Another user's home is separate from mine
      Given I have the folder "Biology" in home
      When another user opens home
      Then it is empty

  Rule: Opening a folder shows what is inside it

    Scenario: Opening a folder lists its decks and notes
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      And I have the note "Atoms" in "Biology"
      When I open the folder "Biology"
      Then the listing shows the deck "Cells" and the note "Atoms"

    Scenario: Opening an empty folder lists nothing
      Given I have the folder "Biology" in home
      When I open the folder "Biology"
      Then it is empty

    @ui
    Scenario: The app lists a folder's decks and notes
      Given the backend has the folder "Biology" holding the deck "Cells" and the note "Atoms"
      When I open the folder "Biology" in the app
      Then the app shows "Cells"
      And the app shows "Atoms"

    @ui
    Scenario: The app invites an import into an empty folder
      Given the backend has the empty folder "Biology"
      When I open the folder "Biology" in the app
      Then the app shows "Nothing here yet"

  Rule: The app says why a page cannot load and offers to retry

    @ui
    Scenario: A folder that cannot load says why
      Given the backend refuses the folder "Biology" with "Folder does not exist!"
      When I open the folder "Biology" in the app
      Then the app shows "Folder does not exist!"
      And the app offers "Try again"

    @ui
    Scenario: A deck that cannot load says why
      Given the backend refuses the deck "Cells" with "Deck does not exist!"
      When I review the deck "Cells" in the app
      Then the app shows "Deck does not exist!"
      And the app offers "Try again"

  Rule: Folders nest inside each other

    Scenario: A folder created inside another appears in it
      Given I have the folder "Biology" in home
      When I create the folder "Cells" in "Biology"
      Then "Biology" contains the folder "Cells"

    Scenario: Folders nest more than one level deep
      Given I have the folder "Biology" in home
      And I have the folder "Cells" in "Biology"
      When I create the folder "Organelles" in "Cells"
      Then "Cells" contains the folder "Organelles"

  Rule: Folders side by side never share a name

    Scenario: A second folder with a taken name gets a number
      Given I have the folder "Biology" in home
      When I create the folder "Biology" in home
      Then home contains the folders "Biology" and "Biology 2"

    Scenario: The same name is free in a different folder
      Given I have the folder "Biology" in home
      And I have the folder "Cells" in "Biology"
      When I create the folder "Cells" in home
      Then home contains the folder "Cells"

  Rule: Deleting a folder deletes everything inside it

    Scenario: A deck inside a deleted folder is gone
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in "Biology" with the card "What is a cell?"
      When I delete the folder "Biology"
      Then the deck "Cells" does not exist

    Scenario: A subfolder of a deleted folder is gone
      Given I have the folder "Biology" in home
      And I have the folder "Cells" in "Biology"
      When I delete the folder "Biology"
      Then the folder "Cells" does not exist

    Scenario: The files of a deleted folder leave the disk
      Given I have the folder "Biology" in home
      And I upload the PDF "cells.pdf" saying "Cells divide" into "Biology"
      When I delete the folder "Biology"
      Then nothing is left on disk

  Rule: Home cannot be deleted

    Scenario: Deleting home is refused
      Given I opened home
      When I delete home
      Then I am told "Home folder cannot be deleted!"

    Scenario: Home keeps its content after a refused delete
      Given I have the folder "Biology" in home
      And I opened home
      When I delete home
      Then home contains the folder "Biology"

  Rule: A folder cannot be moved inside itself

    Scenario: Moving a folder into its own subfolder is refused
      Given I have the folder "Biology" in home
      And I have the folder "Cells" in "Biology"
      When I move the folder "Biology" into "Cells"
      Then I am told "A folder cannot be moved inside itself!"

    Scenario: Moving a folder into itself is refused
      Given I have the folder "Biology" in home
      When I move the folder "Biology" into "Biology"
      Then I am told "A folder cannot be moved inside itself!"

  Rule: I can rename anything I own

    Scenario: A renamed folder shows its new name
      Given I have the folder "Biology" in home
      When I rename the folder "Biology" to "Anatomy"
      Then home contains the folder "Anatomy"

    Scenario: A renamed deck shows its new name
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I rename the deck "Cells" to "Neurons"
      Then home contains the deck "Neurons"

    Scenario: A blank name is refused
      Given I have the folder "Biology" in home
      When I rename the folder "Biology" to " "
      Then I am told "Name cannot be blank!"

  Rule: I can move anything into another folder

    Scenario: A moved deck appears in its new folder
      Given I have the folder "Biology" in home
      And I have the deck "Cells" in home with the card "What is a cell?"
      When I move the deck "Cells" into "Biology"
      Then "Biology" contains the deck "Cells"

    Scenario: A moved folder appears in its new parent
      Given I have the folder "Biology" in home
      And I have the folder "Chemistry" in home
      When I move the folder "Chemistry" into "Biology"
      Then "Biology" contains the folder "Chemistry"

  Rule: I can delete anything I own

    Scenario: A deleted note is gone
      Given I have the note "Cells" in home
      When I delete the note "Cells"
      Then the note "Cells" does not exist

    Scenario: A deleted deck is gone
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I delete the deck "Cells"
      Then the deck "Cells" does not exist

    Scenario: A deleted test is gone
      Given I have the test "Mammals" in home
      When I delete the test "Mammals"
      Then the test "Mammals" does not exist

  Rule: A folder is named when it is made or opened

    Scenario: A folder without a parent is refused
      When I create the folder "Biology" without a parent
      Then I am told "Missing parent folder"

    Scenario: Opening a folder without naming it is refused
      When I open a folder without naming it
      Then I am told "Missing folder id"

    Scenario: Opening a folder with a malformed id is refused
      When I open the folder with the id "not-a-folder-id"
      Then I am told "Folder does not exist!"

  Rule: Only decks, tests, notes, files and folders can be renamed

    Scenario: Renaming a unit of an unknown kind is refused
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I rename the deck "Cells" as a "poster" to "Posters"
      Then I am told "Unknown unit type!"

    Scenario: Renaming a deck as a deck works
      Given I have the deck "Cells" in home with the card "What is a cell?"
      When I rename the deck "Cells" as a "flashcard_deck" to "Cell cards"
      Then home contains the deck "Cell cards"
