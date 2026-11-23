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

    @ui
    Scenario: Importing pasted text in the app asks for all three by default
      Given the backend accepts imports
      When I import the text "Cells are the unit of life." in the app
      Then the backend was asked to generate flashcards, a note and a test from "Cells are the unit of life."

    @ui
    Scenario: Unticking the test in the app leaves the test out
      Given the backend accepts imports
      When I import the text "Cells are the unit of life." in the app without "Test"
      Then the backend was asked to generate flashcards and a note from "Cells are the unit of life."

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

    Scenario: A file that is gone from storage is reported
      Given I upload the PDF "cells.pdf" saying "Cells divide" into home
      And "cells.pdf" is gone from storage
      When I read the text out of "cells.pdf"
      Then I am told "That document is no longer stored"

  Rule: Every kind of uploaded document is read into text

    Scenario: A text file is read as it is
      Given I upload the text file "cells.txt" saying "Cells divide" into home
      When I read the text out of "cells.txt"
      Then I get the text "Cells divide"

    Scenario: A saved web page is read without its markup
      Given I upload the web page file "cells.html" saying "Cells divide" into home
      When I read the text out of "cells.html"
      Then I get the text "Cells divide"
      And the text leaves out "<p>"

    Scenario: The plain body of an email is read
      Given I upload the email "cells.eml" with the plain body "Cells divide" into home
      When I read the text out of "cells.eml"
      Then I get the text "Cells divide"

    Scenario: An email with only an HTML body is read without its markup
      Given I upload the email "cells.eml" with only the HTML body "Cells divide" into home
      When I read the text out of "cells.eml"
      Then I get the text "Cells divide"
      And the text leaves out "<p>"

    Scenario: An email with only an attachment gives no text
      Given I upload the email "empty.eml" with only an attachment into home
      When I read the text out of "empty.eml"
      Then I am told "Could not extract text!"

    Scenario: A Word document is read after LibreOffice turns it into a PDF
      Given LibreOffice converts files to PDF saying "Cells divide"
      And I upload the file "cells.docx" into home
      When I read the text out of "cells.docx"
      Then I get the text "Cells divide"

    Scenario: A file of a kind that holds no readable text gives no text
      Given I upload the file "cells.zip" into home
      When I read the text out of "cells.zip"
      Then I am told "Could not extract text!"

  Rule: Only real pages of a paged document are read

    Scenario: Pages past the end of a document are refused
      Given I upload the 2-page PDF "cells.pdf" into home
      When I read the text out of page 5 of "cells.pdf"
      Then I am told "The document has only 2 pages"

    Scenario: A backwards page range is refused
      Given I upload the 2-page PDF "cells.pdf" into home
      When I read the text out of pages 2 to 1 of "cells.pdf"
      Then the request is refused as invalid

    Scenario: Pages cannot be chosen in a text file
      Given I upload the text file "cells.txt" saying "Cells divide" into home
      When I read the text out of page 1 of "cells.txt"
      Then I am told "Only a document with pages can be read"

    Scenario: Pages of a Word document are read after converting it
      Given LibreOffice converts files to PDF saying "Cells divide"
      And I upload the file "cells.docx" into home
      When I read the text out of page 1 of "cells.docx"
      Then I get the text "Cells divide"

  Rule: Text is read only from a file or a link

    Scenario: Reading with neither a file nor a link gives no text
      When I read the text out of nothing
      Then I am told "Could not extract text!"

    Scenario: A topic is written into a note rather than read
      When I read the text out of the topic "Cell division"
      Then I am told "A topic is written into a note, not extracted."

  Rule: A web page link is read into text for an import

    Scenario: The article of a web page is read
      Given the web page "https://example.com/cells" has a long article saying "Cells divide."
      When I read the text out of the link "https://example.com/cells"
      Then I get the text "Cells divide."

    Scenario: An unreachable web page gives no text
      Given the web page "https://example.com/missing" cannot be reached
      When I read the text out of the link "https://example.com/missing"
      Then I am told "Could not extract text!"

    Scenario: A page without an article is read from its largest block
      Given the web page "https://example.com/cells" has no article but a long block saying "Cells divide."
      When I read the text out of the link "https://example.com/cells"
      Then I get the text "Cells divide."

    Scenario: A page whose article is too short is read from its largest block
      Given the web page "https://example.com/cells" has a short article and a long block saying "Cells divide."
      When I read the text out of the link "https://example.com/cells"
      Then I get the text "Cells divide."

    Scenario: A page with no blocks of text gives no text
      Given the web page "https://example.com/cells" has only the line "Hello"
      When I read the text out of the link "https://example.com/cells"
      Then I am told "Could not extract text!"

    Scenario: A page whose blocks are all short gives no text
      Given the web page "https://example.com/cells" has only the short block "Hello"
      When I read the text out of the link "https://example.com/cells"
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

    Scenario: A transcript written only in another language is still read
      Given the YouTube video "cellvideo01" has only the German transcript "Zellen teilen sich"
      When I read the text out of the link "https://youtu.be/cellvideo01"
      Then I get the text "Zellen teilen sich"

    Scenario: An automatic transcript only in another language is still read
      Given the YouTube video "cellvideo01" has only the automatic German transcript "Zellen teilen sich"
      When I read the text out of the link "https://youtu.be/cellvideo01"
      Then I get the text "Zellen teilen sich"

    Scenario: A video with transcripts turned off is read from its web page
      Given the YouTube video "cellvideo01" has transcripts turned off
      And the web page "https://youtu.be/cellvideo01" has a long article saying "Cells divide."
      When I read the text out of the link "https://youtu.be/cellvideo01"
      Then I get the text "Cells divide."

    Scenario: A video with no transcripts at all is read from its web page
      Given the YouTube video "cellvideo01" has no transcripts
      And the web page "https://youtu.be/cellvideo01" has a long article saying "Cells divide."
      When I read the text out of the link "https://youtu.be/cellvideo01"
      Then I get the text "Cells divide."

    Scenario: A short YouTube link without a video is read as a web page
      Given the web page "https://youtu.be/" has a long article saying "Cells divide."
      When I read the text out of the link "https://youtu.be/"
      Then I get the text "Cells divide."

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

    Scenario: A text recogniser that fails says why
      Given text recognition fails saying "Image too blurry"
      And I upload the image "board.png" into home
      When I read the text out of "board.png"
      Then I am told "Image too blurry"

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

    Scenario: A running card generation is reported as pending
      Given I imported "Cells are the unit of life." into home
      And the card generation is still running
      When I check on the card generation
      Then it is reported as "PENDING"

    Scenario: A finished card generation names its deck
      Given I imported "Cells are the unit of life." into home
      And the card generation finished writing 3 cards into the imported deck
      When I check on the card generation
      Then it reports 3 cards written into the imported deck

    Scenario: A running question generation is reported as pending
      Given I imported "Cells are the unit of life." into home
      And the question generation is still running
      When I check on the question generation
      Then it is reported as "PENDING"

    Scenario: A finished question generation names its test
      Given I imported "Cells are the unit of life." into home
      And the question generation finished writing 4 questions into the imported test
      When I check on the question generation
      Then it reports 4 questions written into the imported test

    Scenario: A made-up generation token is refused
      When I check on the generation "not-a-real-token"
      Then I am told "Task does not exist!"

    Scenario: A generation token with a forged signature is refused
      Given I imported "Cells are the unit of life." into home
      When I check on the note generation with a forged signature
      Then I am told "Task does not exist!"

  Rule: A generation whose destination was deleted meanwhile writes nothing

    Scenario: Cards for a deck deleted meanwhile are refused
      Given the AI writes the deck "Cells" with the card "What is a cell?"
      When the card generation finishes for a deck that was deleted meanwhile
      Then the generation fails because "Flashcard deck does not exist!"

    Scenario: Questions for a test deleted meanwhile are refused
      Given the AI writes the test "Cells quiz" asking "Which is a cell?" with "Neuron" right and "Rock" wrong
      When the question generation finishes for a test that was deleted meanwhile
      Then the generation fails because "Test does not exist!"

    Scenario: A note for a folder deleted meanwhile is refused
      Given the AI writes the note "Cell notes" saying "Cells divide."
      When the note generation finishes for a folder that was deleted meanwhile
      Then the generation fails because "Folder does not exist!"

  Rule: An amount can be given only for a type I ask for

    Scenario: An amount for a type I asked for is passed on
      When I import "Cells are the unit of life." into home asking for 5 basic cards
      Then the basic cards are asked for 5 at a time

    Scenario: An amount for a type I did not ask for is refused
      When I import "Cells are the unit of life." into home asking for basic cards but 5 cloze cards
      Then the request is refused as invalid

  Rule: A generation reads the AI's answer and tries OpenAI twice

    Scenario: An answer wrapped in other words is still read
      Given OpenAI wraps the note "Cell notes" saying "Cells divide." in other words
      When I import "Cells are the unit of life." into home and only a note is generated
      Then home contains the note "Cell notes"

    Scenario: OpenAI that fails once is asked again
      Given OpenAI fails once and then writes the note "Cell notes" saying "Cells divide."
      When I import "Cells are the unit of life." into home and only a note is generated
      Then home contains the note "Cell notes"
      And OpenAI was asked 2 times

    Scenario: OpenAI that fails twice writes nothing
      Given OpenAI fails every time
      When I import "Cells are the unit of life." into home and the note generation fails
      Then OpenAI was asked 2 times
      And home contains no note

    Scenario: An answer with no object in it writes nothing
      Given OpenAI answers the import with "I cannot help with that."
      When I import "Cells are the unit of life." into home and the note generation fails
      Then home contains no note

  Rule: Imports use the chosen AI engine

    Scenario: Claude Code writes the note when it is the chosen engine
      Given Claude Code is the chosen engine and writes the note "Cell notes" saying "Cells divide."
      When I import "Cells are the unit of life." into home and only a note is generated
      Then home contains the note "Cell notes"

    Scenario: Claude Code that returns no text writes nothing
      Given Claude Code is the chosen engine and returns no text
      When I import "Cells are the unit of life." into home and the note generation fails
      Then home contains no note

  Rule: An imported unit remembers where its text came from

    Scenario: A deck imported from a link shows the link
      When I import the text of the link "https://example.com/cells" into home asking for flashcards
      Then home lists a deck from the link "https://example.com/cells"

    Scenario: A deck I made by hand shows no source
      Given I have the deck "Cells" in home with the card "What is a cell?"
      Then home lists the deck "Cells" without a source
