Feature: Timein
  In order to add timesheet entry
  As a user
  I want to timein with the current time

  Background:
    Given I am logged in
    And I am on the "timesheets" page

  Scenario: With complete timesheet entry for previous day of shift
    Given I have timein, timeout entry for previous timesheet
    Then I should see "Time in" button
    When I press "Time in"
    Then I should see my timesheet entry for the day

  Scenario: Late timesheet timein entry
    Given I am late for my shift schedule
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And I should see in field minutes late with value greater than 0

  Scenario: With no timesheet entry for previous day of shift
    Given I have no timein entry for previous timesheet
    And I have no timeout entry for previous timesheet
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And  I should see my previous timesheet marked as AWOL

  Scenario: No timeout entry for previous day of shirt
    Given I have no timeout entry for previous timesheet
    Then I should be prompted to timeout
    And I should not see "Time in" button
