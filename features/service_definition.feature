Feature: Retrieve a service definition for a service
  Given a service
  When I need to know how the service is defined
  In order to interpret the service definition
  I want to retrieve the service definition

  Scenario: definition found
    Given valid service definition
    And a registered service
    And it is described by a service definition
    When I request the service definition
    Then I receive the service definition

  Scenario: no service
    Given no service
    When I request the service definition
    Then I receive 'no service provided' notification

  Scenario: invalid service
    Given invalid service identifier
    When I request the service definition
    Then I receive 'invalid service identifier provided' notification

  Scenario: definition not found
    Given a registered service
    When I request the service definition
    Then I receive 'service has no definition' notification
