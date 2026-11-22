Feature: Import
  Turn a file, a link, an image or text into study units.

  Rule: An import creates exactly the study units I ask for

    Scenario: Asking for all three starts a deck, a note and a test
      Given I have the folder "Biology" in home
      When I import "Cells are the unit of life." into "Biology" asking for flashcards, a note and a test
      Then "Biology" contains a new deck and a new test
      And a note, cards and questions are being generated

    Scenario: Asking only for flashcards starts only a deck
      When I import "Cells are the unit of life." into home asking for flashcards
      Then home contains a new deck and no test
      And only cards are being generated

    Scenario: Asking only for a note starts only a note
      When I import "Cells are the unit of life." into home asking for a note
      Then home contains no deck and no test
      And only a note is being generated

  Rule: A finished generation fills the deck, the test and the note

    Scenario: Generated cards fill the new deck
      Given the AI writes the deck "Cell basics" with the card "What is a cell?"
      When I import "Cells are the unit of life." into home and it is generated
      Then the deck "Cell basics" has the card "What is a cell?"

    Scenario: Generated questions fill the new test
      Given the AI writes the test "Cell quiz" asking "Which is part of a cell?" with "nucleus" right and "pebble" wrong
      When I import "Cells are the unit of life." into home and it is generated
      Then the test "Cell quiz" asks "Which is part of a cell?"

    Scenario: A generated note lands in the folder
      Given the AI writes the note "Cell notes" saying "Cells divide."
      When I import "Cells are the unit of life." into home and it is generated
      Then home contains the note "Cell notes"

  Rule: An import needs text

    Scenario: Importing nothing is refused
      When I import nothing into home
      Then I am told "There is no text to generate from!"

    Scenario: Importing nothing creates no deck and no test
      When I import nothing into home
      Then home contains no deck and no test

  Rule: Text is read out of an uploaded file before an import

    Scenario: The text of an uploaded PDF is read out
      Given I upload the PDF "cells.pdf" saying "Cells divide" into home
      When I read the text out of "cells.pdf"
      Then I get the text "Cells divide"

    Scenario: Only the chosen pages are read
      Given I upload the PDF "cells.pdf" with the pages "Cells divide" and "Atoms bond" into home
      When I read the text out of page 2 of "cells.pdf"
      Then I get the text "Atoms bond"
      And the text leaves out "Cells divide"

  Rule: A web page link is read into text for an import

    Scenario: The article of a web page is read
      Given the web page "https://example.com/cells" has a long article saying "Cells divide."
      When I read the text out of the link "https://example.com/cells"
      Then I get the text "Cells divide."

    Scenario: An unreachable web page gives no text
      Given the web page "https://example.com/missing" cannot be reached
      When I read the text out of the link "https://example.com/missing"
      Then I am told "Could not extract text!"

  Rule: A YouTube link is read from its transcript

    Scenario: A full YouTube link is read from its transcript
      Given the YouTube video "cellvideo01" has the transcript "Cells divide"
      When I read the text out of the link "https://www.youtube.com/watch?v=cellvideo01"
      Then I get the text "Cells divide"

    Scenario: A short YouTube link is read from its transcript
      Given the YouTube video "cellvideo01" has the transcript "Cells divide"
      When I read the text out of the link "https://youtu.be/cellvideo01"
      Then I get the text "Cells divide"

  Rule: Text is read out of an image

    Scenario: The text in an uploaded image is recognised
      Given text recognition reads "Cells divide" from every image
      And I upload the image "board.png" into home
      When I read the text out of "board.png"
      Then I get the text "Cells divide"

    Scenario: A missing text recogniser is reported
      Given text recognition is not available
      And I upload the image "board.png" into home
      When I read the text out of "board.png"
      Then I am told text recognition is not available

  Rule: I can follow each generation until it finishes

    Scenario: A running note generation is reported as pending
      Given I imported "Cells are the unit of life." into home
      And the note generation is still running
      When I check on the note generation
      Then it is reported as "PENDING"

    Scenario: A finished note generation names the note
      Given I imported "Cells are the unit of life." into home
      And the note generation finished with the note "Cell notes"
      When I check on the note generation
      Then it reports the note "Cell notes"

    Scenario: Another user cannot follow my generation
      Given I imported "Cells are the unit of life." into home
      When another user checks on the note generation
      Then they are told "Task does not exist!"
