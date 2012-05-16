Feature: Login
  In order to access account
  As a user
  I want to login using my LDAP account

  Scenario: With Correct Password and Username
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Sign in"
    Then I should be on the "timesheets" page

  Scenario: With Wrong Password and Username
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | wrong login    |
      | user[password] | wrong password |
    And I press "Sign in"
    Then I should be on the "signin" page
    
  Scenario: Root page without Authorization
    Given I am not authorized
    When I go to the "root" page
    Then I should be on the "signin" page
    
  Scenario: Root page with Authorization
    Given I am authorized
    When I go to the "root" page
    Then I should be on the "timesheets" page
    
  Scenario: Cannot connect to LDAP
    Given I go to the "signin" page
    When I fill in the following:
      | field          | value          |
      | user[login]    | ldaplogin      |
      | user[password] | ldappassword   |
    And I press "Sign in"
    Then I should get a response of status 500

