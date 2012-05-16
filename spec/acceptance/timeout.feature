Feature: Timeout
  In order to add timesheet entry
  As a user
  I want to timeout with the current time

  Background:
    Given I am logged in
    And I am on the "timesheets" page

  Scenario: Latest timesheet entry has value for time in
    Then I should see "Time out" button
    When I press "Time out"
    Then I should see my timesheet entry for the day
