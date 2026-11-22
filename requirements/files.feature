Feature: Files
  Upload any file, read it as a PDF and keep my place in it.

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

    @ui
    Scenario: Settings offers LibreOffice when it is missing
      When I open Settings in the app
      Then the app offers "Download"

    @ui
    Scenario: Downloading LibreOffice in Settings installs it
      When I open Settings in the app
      And I press "Download"
      Then the app offers "Remove"

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

    @ui
    Scenario: Bookmarking the page in view in the app saves it
      Given the backend keeps bookmarks for the 3-page file "cells.pdf"
      When I read "cells.pdf" in the app as far as page 2
      And I bookmark the page in view
      Then the backend saved page 2 of "cells.pdf"
      And the app offers to remove the bookmark on page 2

    @ui
    Scenario: A bookmarked file opens on its page in the app
      Given the backend keeps bookmarks for the 3-page file "cells.pdf" bookmarked on page 2
      When I read "cells.pdf" in the app
      Then the app offers to remove the bookmark on page 2

