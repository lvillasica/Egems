Feature: Login
  In order to access account
  As a user
  I want to login

  Scenario: Login Successfully
    Given I go to the "login_page"
    When I fill in the following:
      | field             | value |
      | session[login]    | hello |
      | session[password] | hello |
    And I press "Login"
    Then I should not be on the "timesheets" page

  Scenario: Login Failure
    Given I go to the "login_page"
    When I fill in the following:
      | field             | value          |
      | session[login]    | wrong password |
      | session[password] | wrong password |
    And I press "Login"
    Then I should be on the "timesheets" page

