module ServiceRegistry
  module Test
    class StubServiceDefinitionOrchestrationProvider < OrchestrationProvider
      def service_definition_changed?
        result = @iut.service_definition_for_service(@service.is_a?(Hash) ? @service['id'] : @service)
        @current_definition = result['status'] == 'fail' ? nil : result['data']['definition']
        not (@current_definition == @pre_service_definition)
      end

      def given_a_valid_service_definition
        @service_definition = @service_definition_1
      end

      def deregister_service_definition
        process_result(@iut.deregister_service_definition(@service.is_a?(Hash) ? @service['id'] : @service))
      end

      def given_invalid_service_definition
        @service_definition = "blah"
      end

      def given_no_service_definition
        @service_definition = nil
      end

      def request_service_definition
        process_result(@iut.service_definition_for_service(@service.is_a?(Hash) ? @service['id'] : @service))
      end

      def has_received_service_definition?
        data['definition'] == @service_definition_1
      end

      def is_service_described_by_service_definition?
        process_result(@iut.service_definition_for_service(@service.is_a?(Hash) ? @service['id'] : @service))
        data['definition'] == @service_definition
      end

      def given_existing_service_identifier
        @service = @service_1['id']
      end

      def no_service_definition_associated
        # By default no service definition associated
      end
    end
  end
end

ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("stub", "Registering service definitions", ServiceRegistry::Test::StubServiceDefinitionOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("stub", "Deregistering a service definition", ServiceRegistry::Test::StubServiceDefinitionOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("stub", "Retrieve a service definition for a service", ServiceRegistry::Test::StubServiceDefinitionOrchestrationProvider)