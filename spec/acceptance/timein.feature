Feature: Timein
  In order to add timesheet entry
  As a user
  I want to timein with the current time

  Background:
    Given I am logged in
    And I am on the "timesheets" page

  Scenario: With complete timesheet entry for previous day of shift
    Then I should see "Time in" button
    When I press "Time in"
    Then I should see my timesheet entry for the day

  Scenario: Late timesheet timein entry
    Given I am late for my shift schedule
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And I should see in field minutes late with value greater than 0

  Scenario: With no timesheet entry for previous day of shift
    Given I have no timesheet entry for previous day of shift
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And  I should see my previous day of shift timesheet marked as AWOL
