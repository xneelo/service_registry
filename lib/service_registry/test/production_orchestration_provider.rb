module ServiceRegistry
  module Test
    class ProductionServiceOrchestrationProvider < OrchestrationProvider

      def given_invalid_service_for_registration
        @service = { 'id' => "" }
      end

      def given_new_service
        @service = @service_2
      end

      def given_a_need
        @need = 'valid'
      end

      def given_a_pattern
        @need = 'entropy'
      end

      def given_service_with_pattern_in_id
        @expected_pattern_service = @service_3
        @iut.register_service(@service_3)
        @iut.register_service_definition(@service_3['id'], @service_definition_1)
      end

      def given_service_with_pattern_in_description
        @expected_pattern_service = @service_4
        @iut.register_service(@service_4)
        @iut.register_service_definition(@service_4['id'], @service_definition_1)
      end

      def given_service_with_pattern_in_definition
        @expected_pattern_service = @service_5
        @iut.register_service(@service_5)
        @iut.register_service_definition(@service_5['id'], @service_definition_1)
      end

      def no_services_match_need
        @need = 'no services match this'
      end

      def register_service
        process_result(@iut.register_service(@service))
      end

      def deregister_service
        process_result(@iut.deregister_service(@service.is_a?(Hash) ? @service['id'] : @service))
      end

      def match_need
        process_result(@iut.search_for_service(@need))
      end

      def provide_one_matching_service
        @service = @service_1['id']
        @iut.register_service(@service_1)
        @iut.register_service_definition(@service_1['id'], @service_definition_1)
      end

      def provide_two_matching_services
        @iut.register_service(@service_1)
        @iut.register_service(@service_2)
        @iut.register_service_definition(@service_1['id'], @service_definition_1)
        @iut.register_service_definition(@service_2['id'], @service_definition_1)
      end

      def service_by_id
        process_result(@iut.service_by_id(@service))
      end

      def multiple_existing_services
        @iut.register_service(@service_1)
        @iut.register_service(@service_4)
        @expected_pattern_service = @service_4
        @iut.register_service_definition(@service_4['id'], @service_definition_1)
      end

      def multiple_existing_service_components
        @iut.register_service_component(@service_component_1)
        @iut.register_service_component(@service_component_2)
        @iut.associate_service_component_with_service(@service_4['id'], @service_component_2)
        @iut.associate_service_component_with_service(@service_1['id'], @service_component_1)
      end

      def multiple_existing_domain_perspectives
        @iut.register_domain_perspective(@domain_perspective_1)
        @iut.register_domain_perspective(@domain_perspective_2)
      end

      def service_components_registered_in_different_domain_perspectives
        @iut.associate_service_component_with_domain_perspective(@domain_perspective_2, @service_component_1)
        @iut.associate_service_component_with_domain_perspective(@domain_perspective_1, @service_component_2)
      end

      def match_pattern_in_domain_perspective
        process_result(@iut.search_domain_perspective(@domain_perspective_1, @need))
      end

      def service_definitions
        process_result(@iut.service_definitions(service_component))
      end

      def received_no_services?
        success? and (data['services'] == [])
      end

      def service_available?
        id = @service.nil? ? "" : @service['id']
        process_result(@iut.service_registered?(id))
        data['registered']
      end

      def services_found?
        not data['services'].empty?
      end

      def single_service_match?
        (data['services'].count == 1) and (data['services'].first['id'] == @service_1['id'])
      end

      def multiple_services_match?
        (data['services'].count == 2) and ((data['services'][0]['id'] == @service_1['id']) or (data['services'][0]['id'] == @service_2['id'])) and ((data['services'][1]['id'] == @service_1['id']) or (data['services'][1]['id'] == @service_2['id']))
      end

      def entry_matches?
        data['services'].first['id'].include?(@need) == true
      end

      def both_entries_match?
        data['services'][0]['id'].include?(@need) == true
        data['services'][1]['id'].include?(@need) == true
      end

      def service_matched_pattern?
        (data['services'].count == 1) and (data['services'].first['id'] == @expected_pattern_service['id'])
      end

      def matched_pattern_in_domain_perspectice?
        data['services'].size == 1
      end

      def matched_only_in_domain_perspective?
        data['services'][0] == @service_4
      end

      def has_list_of_service_components_providing_service?
        data['services'][0]['service_components'].count > 0
      end

      def has_list_of_both_service_components_providing_service?
        scs = data['services'][0]['service_components']
        (scs.count > 0) and (not scs[@service_component_1].nil?) and (not scs[@service_component_2].nil?)
      end

      def has_uri_to_service_component_providing_service?
        sc = data['services'][0]['service_components'][@service_component]
        sc['uri'] == @valid_uri
      end

      def has_status_of_service_component_providing_service?
        sc = data['services'][0]['service_components'][@service_component]
        sc['status'] == '100'
      end
    end
  end
end

ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("production", "De-registering a service", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("production", "Registering services", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("production", "Searching for a service", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("production", "Map service components to services", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)

ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("tfa", "De-registering a service", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("tfa", "Registering services", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("tfa", "Searching for a service", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
ServiceRegistry::Test::OrchestrationProviderRegistry.instance.register("tfa", "Map service components to services", ServiceRegistry::Test::ProductionServiceOrchestrationProvider)
