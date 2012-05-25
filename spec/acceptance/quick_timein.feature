Feature: Quick Timein
  In order to have a faster way to timein
  As a user
  I want to timein with the current time automatically after signin

  Scenario: Successful time in after signin
    Given I time in as "ldaplogin" with password "ldappassword"
    And I have no invalid time entries
    Then I should be on the "timesheets" page
    And I should see my time entry today

  Scenario: With Wrong Password and Username
    Given I time in as "ldaplogin" with password "wrong"
    Then I should be on the "signin" page

  Scenario: With no timeout entry for previous day of shift
    Given I time in as "ldaplogin" with password "ldappassword"
    And I have not timeout yesterday
    When I go to the "timesheets" page
    Then I should be prompted to timeout
    When I submit missing timeout
    Then I should see my timeout from the previous day
