Feature: Desktop backend
  The desktop app starts its own backend on this Mac, and that backend
  lives exactly as long as the app does.

  Rule: The app starts its own backend and opens home

    @ui
    Scenario: A started backend opens home
      Given the backend starts
      When the app opens
      Then the app opens home

    @ui
    Scenario: A backend that cannot start says why and offers to retry
      Given the backend cannot start because "Port 4100 is taken"
      When the app opens
      Then the app shows "Port 4100 is taken"
      And the app offers "Try again"

  Rule: The desktop backend stops when the app that started it exits

    Scenario: The backend stops once its app has gone
      Given the desktop backend watches the app with process id 4242
      When the app with process id 4242 exits
      Then the desktop backend stops itself

    Scenario: The backend keeps running while its app runs
      Given the desktop backend watches the app with process id 4242
      When the app keeps running
      Then the desktop backend keeps running

    Scenario: Stopping the backend ends its own process
      When the desktop backend stops its own process
      Then it sends its own process the termination signal

  Rule: The desktop backend listens only on this Mac, on the port the app chose

    Scenario: Every unprivileged port the app chooses is accepted
      Then every port from 1024 to 65535 is accepted for the desktop backend

    Scenario: A privileged or impossible port is refused
      Then every port below 1024 or above 65535 is refused for the desktop backend

    Scenario: A port that is not a whole number is refused
      Then every port that is not a whole number is refused for the desktop backend

    Scenario: The desktop backend listens only on this Mac
      When the desktop backend starts on port 4100 for the app with process id 4242
      Then it listens on "127.0.0.1" port 4100

  Rule: The desktop backend refuses to start without knowing its app

    Scenario: A missing or unreadable app process id is refused
      Then every missing or unreadable app process id is refused

    Scenario: Process id 1 is refused as the app
      Then the app process id 1 is refused

  Rule: The desktop backend generates study units without a separate worker

    Scenario: Queued generation finishes inside the backend
      When the desktop backend starts its generation worker
      And a generation job doubling 21 is queued
      Then the job finishes inside the backend with 42

    Scenario: The generation worker never keeps the backend alive
      When the desktop backend starts its generation worker
      Then the worker thread ends with the backend

  Rule: The desktop backend brings its database up to date when it starts

    Scenario: A fresh database gets every table it needs
      When the desktop backend upgrades a fresh database
      Then the database has the tables "folders", "flashcard_decks", "notes" and "files"

    Scenario: Upgrading an up-to-date database again keeps it current
      When the desktop backend upgrades a fresh database twice
      Then the database is at the latest revision
