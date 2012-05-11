Feature: Timein
  In order to add timesheet entry
  As a user
  I want to timein with the current time

  Background:
    Given Im logged in as "Tudor"
    And Im on the "timesheet" page

  Scenario: Before considered late
    When I press "Time in"
    Then I should see my timesheet entry for the day

  Scenario: As late timesheet entry
    Given "Tudor" is late with regards to this shif schedule
    When I press "Time in"
    Then I should see my timesheet entry with late status

  Scenario: With no timeout of the previous day
    Given "Tudor" has no logged out entry of yesterday
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And  I should see my yesterday timesheet marked as for validation

  Scenario: With no timesheet entry of yesterday
    Given "Tudor" has no timesheet entry of yesterdy
    When I press "Time in"
    Then I should see my timesheet entry for the day
    And  I should see my yesterday timesheet marked as AWOL
