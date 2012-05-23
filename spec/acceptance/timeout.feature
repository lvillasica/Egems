Feature: Timeout
  In order to add timesheet entry
  As a user
  I want to timeout with the current time

  Background:
    Given I sign in as "ldaplogin" with password "ldappassword"
    And I am on the "timesheets" page

  Scenario: Latest timesheet entry has value for time in
    Given I have timein today but no timeout
    When I go to the "timesheets" page
    Then I should see the "Time out" link
    When I press "Time out"
    Then I should see my timeout

  Scenario: Latest timesheet entry has no value for time in
    Given I have not timein
