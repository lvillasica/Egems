Feature: Login
  In order to access account
  As a user
  I want to login using my LDAP account

  Scenario: With Correct Password and Username
    Given I sign in as "ldaplogin" with password "ldappassword"
    Then I should be on the "timesheets" page

  Scenario: With Wrong Password and Username
    Given I sign in as "ldaplogin" with password "wrong"
    Then I should be on the "signin" page

  Scenario: Root page without Authorization
    Given I sign in as "ldaplogin" with password "wrong"
    When I go to the "root" page
    Then I should be on the "signin" page

  Scenario: Root page with Authorization
    Given I sign in as "ldaplogin" with password "ldappassword"
    When I go to the "root" page
    Then I should be on the "timesheets" page
