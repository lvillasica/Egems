Feature: Quick Timein
  In order to have a faster way to timein
  As a user
  I want to timein with the current time automatically after signin
  
  Scenario: Successful time in after signin
    Given I go to the "signin" page
    And I have no invalid entries for the past days
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Time in"
    Then I should be on the "timesheets" page
    And I should have time in value for the current time

  Scenario: With Wrong Password and Username
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | wrong login    |
      | user[password] | wrong password |
    And I press "Time in"
    Then I should be on the "signin" page
    
  Scenario: With no timesheet entry for previous day of shift
    Given I go to the "signin" page
    And I have no timeout entry for previous timesheet
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Time in"
    Then I should be on the "timesheets" page
    And I should see my timesheet entry for the day
    And I should see my previous timesheet marked as AWOL

