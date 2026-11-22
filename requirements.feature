Feature: Leffic
  Turn any material into flashcards, a note and a test, then review
  them exactly when you are about to forget.

  Rule: Without a sign-in nothing is reachable

    Scenario: Opening home without signing in is refused
      When someone opens home without signing in
      Then they are refused as not signed in

    Scenario: A forged sign-in is refused
      When someone opens home with a forged sign-in
      Then they are refused as not signed in

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

  Rule: A test scores my answers

    Scenario: Choosing the right option counts as correct
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 1 answer right and missed none

    Scenario: Choosing a wrong option counts as missed
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "shark" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 0 answers right and missed "Which is a mammal?"

  Rule: A true or false question scores my answer

    Scenario: A true statement answered True counts as correct
      Given I have the test "Mammals" in home
      And "Mammals" states "A whale is a mammal." which is true
      When I answer "A whale is a mammal." with "True" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 1 answer right and missed none

    Scenario: A true statement answered False counts as missed
      Given I have the test "Mammals" in home
      And "Mammals" states "A whale is a mammal." which is true
      When I answer "A whale is a mammal." with "False" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 0 answers right and missed "A whale is a mammal."

  Rule: A short-answer question scores my answer

    Scenario: A typed answer counts whatever its capitals
      Given I have the test "Capitals" in home
      And "Capitals" asks "What is the capital of France?" expecting "Paris"
      When I type "paris" for "What is the capital of France?" in the test "Capitals"
      And I finish the test "Capitals"
      Then I got 1 answer right and missed none

    Scenario: A wrong typed answer counts as missed
      Given I have the test "Capitals" in home
      And "Capitals" asks "What is the capital of France?" expecting "Paris"
      When I type "Lyon" for "What is the capital of France?" in the test "Capitals"
      And I finish the test "Capitals"
      Then I got 0 answers right and missed "What is the capital of France?"

  Rule: A test resumes where I left off

    Scenario: Reopening a test shows the answer I gave
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I open the test "Mammals" again
      Then "Which is a mammal?" still shows my answer "whale"

    Scenario: A finished test starts again with no answers
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I finish the test "Mammals"
      And I open the test "Mammals" again
      Then "Which is a mammal?" has no answer yet

  Rule: I can retry only the questions I missed

    Scenario: A retry asks only the missed question
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      And "Mammals" asks "Which is a bird?" with "eagle" right and "bat" wrong
      When I answer "Which is a mammal?" with "shark" in the test "Mammals"
      And I answer "Which is a bird?" with "eagle" in the test "Mammals"
      And I finish the test "Mammals"
      Then retrying the missed questions of "Mammals" asks only "Which is a mammal?"

    Scenario: A retry after a perfect test asks nothing
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I finish the test "Mammals"
      Then retrying the missed questions of "Mammals" asks nothing

  Rule: Questions come one page at a time

    Scenario: The first page holds as many questions as asked for
      Given I have the test "Mammals" in home
      And "Mammals" has 3 questions
      When I open page 1 of the test "Mammals" with 2 questions per page
      Then I see 2 of 3 questions

    Scenario: The last page holds the rest
      Given I have the test "Mammals" in home
      And "Mammals" has 3 questions
      When I open page 2 of the test "Mammals" with 2 questions per page
      Then I see 1 of 3 questions

  Rule: Opening a note marks it read

    Scenario: A note I opened counts as read
      Given I have the note "Cells" in home
      When I open the note "Cells"
      Then the note "Cells" is read

    Scenario: A note I have not opened stays unread
      Given I have the note "Cells" in home
      When I open home
      Then the note "Cells" is not read yet

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

  Rule: A folder counts my read and unread notes across every folder beneath it

    Scenario: Notes in subfolders are counted
      Given I have the folder "Biology" in home
      And I have the note "Cells" in "Biology"
      And I have the note "Atoms" in home
      And I opened the note "Atoms"
      When I ask how many notes are read in home
      Then home has 1 note unread and 1 read

    Scenario: A folder without notes says so
      Given I opened home
      When I ask how many notes are read in home
      Then I am told "No notes!"

  Rule: A folder counts the test questions I have mastered

    Scenario: A question answered right is mastered
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I ask how many questions I have mastered in home
      Then home has 1 of 1 questions mastered

    Scenario: A question answered wrong is not mastered
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "shark" in the test "Mammals"
      And I ask how many questions I have mastered in home
      Then home has 0 of 1 questions mastered

  Rule: A note shows how many minutes it takes to read

    Scenario: A short note takes one minute
      Given I have the note "Cells" in home
      When I open home
      Then home lists the note "Cells" as a 1-minute read

    Scenario: A long note takes longer
      Given I have the note "Essay" of 600 words in home
      When I open home
      Then home lists the note "Essay" as a 3-minute read

  Rule: An uploaded file appears in its folder

    Scenario: An uploaded PDF is listed in home
      When I upload the PDF "cells.pdf" saying "Cells divide" into home
      Then home contains the file "cells.pdf"

    Scenario: Several files uploaded together all appear
      When I upload the PDFs "cells.pdf" and "atoms.pdf" into home
      Then home contains the file "cells.pdf"
      And home contains the file "atoms.pdf"

  Rule: Any uploaded file opens as a PDF

    Scenario: An uploaded PDF opens as a PDF
      Given I upload the PDF "cells.pdf" saying "Cells divide" into home
      When I open the file "cells.pdf"
      Then I get a PDF

    Scenario: An office file is converted to a PDF
      Given LibreOffice converts files to PDF
      And I upload the file "slides.pptx" into home
      When I open the file "slides.pptx"
      Then I get a PDF

  Rule: An office file needs LibreOffice to open

    Scenario: Opening a slide deck without LibreOffice says so
      Given LibreOffice is not installed
      And I upload the file "slides.pptx" into home
      When I open the file "slides.pptx"
      Then I am told LibreOffice is not installed

    Scenario: Reading the text of an office file without LibreOffice says so
      Given LibreOffice is not installed
      And I upload the file "essay.docx" into home
      When I read the text out of "essay.docx"
      Then I am told LibreOffice is not installed

  Rule: Deleting a file also removes it from disk

    Scenario: A deleted file leaves nothing on disk
      Given I upload the PDF "cells.pdf" saying "Cells divide" into home
      When I delete the file "cells.pdf"
      Then the file "cells.pdf" does not exist
      And nothing is left on disk

    Scenario: Deleting one file keeps the others
      Given I upload the PDFs "cells.pdf" and "atoms.pdf" into home
      When I delete the file "cells.pdf"
      And I open the file "atoms.pdf"
      Then I get a PDF

  Rule: A file remembers the page I stopped on

    Scenario: A bookmarked PDF reopens on its page
      Given I upload the 3-page PDF "cells.pdf" into home
      When I stop reading "cells.pdf" on page 2
      Then "cells.pdf" opens on page 2

    Scenario: A removed bookmark leaves the file without one
      Given I upload the 3-page PDF "cells.pdf" into home
      And I stopped reading "cells.pdf" on page 2
      When I remove the bookmark of "cells.pdf"
      Then "cells.pdf" has no bookmark

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

  Rule: I can edit a test question

    Scenario: An edited question shows its new wording
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I reword "Which is a mammal?" as "Which animal is a mammal?"
      Then the test "Mammals" asks "Which animal is a mammal?"

    Scenario: An edited right answer is scored as right
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I change the right answer of "Which is a mammal?" to "dolphin"
      And I answer "Which is a mammal?" with "dolphin" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 1 answer right and missed none

  Rule: Ask answers with Claude Code

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

  Rule: Ask says clearly when Claude Code cannot answer

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

  Rule: Ask uses OpenAI when that engine is chosen

    Scenario: OpenAI answers the question
      Given OpenAI is chosen and answers "Cells are the unit of life."
      When I ask "What is a cell?"
      Then I get the answer "Cells are the unit of life."

    Scenario: OpenAI without a key says how to set it up
      Given OpenAI is chosen without a key
      When I ask "What is a cell?"
      Then I am told "OpenAI is not set up. Add an OpenAI API key in Settings, or choose Claude Code there."

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
