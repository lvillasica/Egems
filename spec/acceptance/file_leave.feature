Feature: File Leave
  In order to file a leave
  As a user
  I want to enter the type of leave and the duration

  Background:
    Given I sign in as "ldaplogin" with password "ldappassword"
    And I am on the "timesheets" page
    
  Scenario: Filling a Vacation Leave
    When I go to the "leaves" page
    Then I should see the "Apply for Leave" link
    When I press "Apply for Leave"
    Then I should see "Vacation" link
    When I press "Vacation"
    Then I should be on the "new_leave_details" page
    When fill in the leave form
    And press "Create"
    Then I should be on the "leave_details" page
    And see my pending leave
