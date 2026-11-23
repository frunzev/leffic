Feature: Tests
  Answer questions, see the score and retry what was missed.

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

    @ui
    Scenario: Taking a test in the app shows my score
      Given the backend has the test "Mammals" asking "Which is a mammal?" with "whale" right and "shark" wrong
      When I take the test "Mammals" in the app choosing "whale"
      Then the backend received my answer "whale"
      And the app shows "1 / 1"

    @ui
    Scenario: A wrong choice in the app is scored as missed
      Given the backend has the test "Mammals" asking "Which is a mammal?" with "whale" right and "shark" wrong
      When I take the test "Mammals" in the app choosing "shark"
      Then the backend received my answer "shark"
      And the app shows "0 / 1"

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

  Rule: My last answer to a question is the one that counts

    Scenario: A changed answer replaces the first one
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "shark" in the test "Mammals"
      And I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 1 answer right and missed none

    Scenario: Changing a right answer to a wrong one counts as missed
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I answer "Which is a mammal?" with "shark" in the test "Mammals"
      And I finish the test "Mammals"
      Then I got 0 answers right and missed "Which is a mammal?"

  Rule: I can answer every question in a folder at once

    Scenario: A folder's questions come from every test beneath it
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      And I have the folder "Biology" in home
      And I have the test "Birds" in "Biology"
      And "Birds" asks "Which is a bird?" with "eagle" right and "bat" wrong
      When I open the questions of home
      Then I see the questions "Which is a mammal?" and "Which is a bird?"

    Scenario: An answer given in a folder session is scored
      Given I have the folder "Biology" in home
      And I have the test "Birds" in "Biology"
      And "Birds" asks "Which is a bird?" with "eagle" right and "bat" wrong
      When I answer "Which is a bird?" with "eagle" in the questions of home
      And I finish the questions of home
      Then I got 1 answer right and missed none

    Scenario: A question outside a folder session cannot be answered in it
      Given I have the folder "Biology" in home
      And I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the questions of "Biology"
      Then I am told "Test item does not exist!"

    Scenario: Asking for questions without a test or folder is refused
      When I ask for questions without naming a test or folder
      Then I am told "Test or folder is required!"

  Rule: A test session belongs to one test and one user

    Scenario: Opening a test with its own session shows my answers
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in the test "Mammals"
      And I open the test "Mammals" with the session I answered in
      Then "Which is a mammal?" still shows my answer "whale"

    Scenario: Opening a test with another test's session is refused
      Given I have the test "Mammals" in home
      And I have the test "Birds" in home
      When I open the test "Birds" with the session of "Mammals"
      Then I am told "Test session does not exist!"

    Scenario: Answering in an unknown session is refused
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I answer "Which is a mammal?" with "whale" in an unknown session
      Then I am told "Test item does not exist!"

    Scenario: Another user cannot answer my question
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When another user answers "Which is a mammal?" with "whale"
      Then they are told "Test item does not exist!"

  Rule: Scores exist only once there is something to score

    Scenario: A folder without questions has no mastery count
      Given I have the folder "Biology" in home
      When I ask how many questions I have mastered in "Biology"
      Then I am told "No test stats!"

    Scenario: Finishing a test without answering gives no score
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with "whale" right and "shark" wrong
      When I finish the test "Mammals" without answering
      Then I am told "No test stats!"

  Rule: Unusual questions and answers are still scored safely

    Scenario: A question without wrong options offers only the right one
      Given I have the test "Mammals" in home
      And "Mammals" asks "Which is a mammal?" with only "whale" as an option
      When I open the test "Mammals" again
      Then "Which is a mammal?" offers only "whale"

    Scenario: A typed answer that is not text counts as missed
      Given I have the test "Capitals" in home
      And "Capitals" asks "What is the capital of France?" expecting "Paris"
      When I send the number 7 as my answer to "What is the capital of France?" in the test "Capitals"
      And I finish the test "Capitals"
      Then I got 0 answers right and missed "What is the capital of France?"
