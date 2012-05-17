Feature: Auto Timein
  In order to have a faster way to timein
  As a user
  I want to timein with the current time automatically after signin
  
  Scenario: With no entry for the day of shift
    Given I go to the "signin" page
    And I have no time entries for today
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Sign in"
    Then I should be on the "timesheets" page
    And I should have time in with the current time
    
  Scenario: With entry for the day of shift and has time out
    Given I go to the "signin" page
    And I have entries for today with latest timeout
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Sign in"
    Then I should be on the "timesheets" page
    And I should have time in with the current time
