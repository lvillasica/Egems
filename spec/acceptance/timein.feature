Feature: Timein
  In order to add timesheet entry
  As a user
  I want to timein with the current time

  Background:
    Given I sign in as "ldaplogin" with password "ldappassword"
    And I am on the "timesheets" page

  Scenario: with complete and valid timesheet entries
    Given I have valid time entries
    When I go to the "timesheets" page
    Then I should see the "Time in" link
    When I press "Time in"
    Then I should see my time entry today

  Scenario: with no timeout entry for yesterday
    Given I have not timeout yesterday
    When I go to the "timesheets" page
    Then I should not see "Time in" link
    And I should be prompted to timeout
    When I submit missing timeout
    Then I should see my timeout from the previous day

  Scenario: with timein for today but no timeout
    Given I have timein today but no timeout
    When I go to the "timesheets" page
    Then I should see my time entry today
    And I should see the "Time in" link
    When I press "Time in"
    And I should be prompted to timeout
    When I submit missing timeout
    Then I should see my timeout from the previous day

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
