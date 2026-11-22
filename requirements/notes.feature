Feature: Notes
  Read generated notes and keep track of what was read.

  Rule: I can mark a note as read

    Scenario: A note I marked counts as read
      Given I have the note "Cells" in home
      When I mark the note "Cells" as read
      Then the note "Cells" is read

    Scenario: A note I have not marked stays unread
      Given I have the note "Cells" in home
      When I open home
      Then the note "Cells" is not read yet

    @ui
    Scenario: Pressing Mark as read in the app marks the note read
      Given the backend has the unread note "Cells"
      When I open the note "Cells" in the app
      And I press "Mark as read"
      Then the backend received the note "Cells" as read
      And the app shows "Marked as read"

    @ui
    Scenario: The app shows a note that is already read
      Given the backend has the read note "Cells"
      When I open the note "Cells" in the app
      Then the app shows "Marked as read"

  Rule: A note shows how many minutes it takes to read

    Scenario: A short note takes one minute
      Given I have the note "Cells" in home
      When I open home
      Then home lists the note "Cells" as a 1-minute read

    Scenario: A long note takes longer
      Given I have the note "Essay" of 600 words in home
      When I open home
      Then home lists the note "Essay" as a 3-minute read

  Rule: A folder counts my read and unread notes across every folder beneath it

    Scenario: Notes in subfolders are counted
      Given I have the folder "Biology" in home
      And I have the note "Cells" in "Biology"
      And I have the note "Atoms" in home
      And I marked the note "Atoms" as read
      When I ask how many notes are read in home
      Then home has 1 note unread and 1 read

    Scenario: A folder without notes says so
      Given I opened home
      When I ask how many notes are read in home
      Then I am told "No notes!"
