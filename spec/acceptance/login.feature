Feature: Login
  In order to access account
  As a user
  I want to login

  Scenario: With Correct Password and Email
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Sign in"
    Then I should not be on the "timesheets" page

  Scenario: With Wrong Password and Email
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | wrong login    |
      | user[password] | wrong password |
    And I press "Sign in"
    Then I should be on the "signin" page

