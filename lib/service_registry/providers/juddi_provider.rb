require 'net/http'
require 'byebug'

module ServiceRegistry
  module Providers
    class JUDDIProvider < BootstrappedProvider
      def initialize(urns, connector)
        @urns = urns
        @connector = connector
      end

      def set_uri(uri)
        @connector.set_uri(uri)
      end

      def authenticate(auth_user, auth_password)
        @connector.authenticate(auth_user, auth_password)
      end

      def available?
        { 'available' => @connector.check_availability }
      end

      def assign_service_to_business(name, business_key = @urns['company'])
        @connector.authorize
        result = @juddi.get_service(name)
        service = result['data']
        @connector.save_service_element(service['name'], service['description'], service['definition'], @urns['services'], business_key)
      end

      def assign_service_component_to_business(name, business_key = @urns['company'])
        @connector.authorize
        result = @juddi.get_service_component(name)
        service = result['data']
        @connector.save_service_element(service['name'], service['description'], service['definition'], @urns['service-components'], business_key)
      end

      def get_service(name)
        @connector.get_service_element(name, @urns['services'])
      end

      def save_service(name, description = nil, definition = nil)
        @connector.authorize
        @connector.save_service_element(name, description.is_a?(Array) ? description : [description], definition, @urns['services'], @urns['company'])
      end

      def delete_service(name)
        @connector.authorize
        @connector.delete_service_element(name, @urns['services'])
      end

      def find_services(pattern = nil)
        pattern = pattern.nil? ? '%' : "%#{pattern}%"

        @connector.find_services(pattern)
      end

      def add_service_uri(service, uri)
        @connector.authorize
        result = service_uris(service)
        existing_id = nil
        result['data']['bindings'] ||= {}
        result['data']['bindings'].each do |binding, detail|
          existing_id = binding if detail['access_point'] == uri
        end
        result = @connector.delete_binding(existing_id) if existing_id
        result = @connector.save_element_bindings(service, [uri], @urns['services'], "service uri") if result['status'] == 'success'
        result
      end

      def remove_service_uri(service, uri)
        @connector.authorize
        result = service_uris(service)
        existing_id = nil
        result['data']['bindings'] ||= {}
        result['data']['bindings'].each do |binding, detail|
          existing_id = binding if detail['access_point'] == uri
        end
        result = @connector.delete_binding(existing_id) if existing_id
        result
      end

      def service_uris(service)
        @connector.find_element_bindings(service, @urns['services'])
      end

      def get_service_component(name)
        @connector.get_service_element(name, @urns['service-components'])
      end

      def save_service_component(name, description = nil, definition = nil)
        @connector.authorize
        @connector.save_service_element(name, description.is_a?(Array) ? description : [description], definition, @urns['service-components'], @urns['company'])
      end

      def delete_service_component(name)
        @connector.authorize
        @connector.delete_service_element(name, @urns['service-components'])
      end

      def find_service_components(pattern = nil)
        pattern = pattern.nil? ? '%' : "%#{pattern}%"

        @connector.find_service_components(pattern)
      end

      def save_service_component_uri(service_component, uri)
        @connector.authorize
        result = @connector.find_element_bindings(service_component, @urns['service-components'])
        # only one binding for service components
        if result and result['data'] and result['data']['bindings'] and (result['data']['bindings'].size > 0)
          result['data']['bindings'].each do |binding, detail|
            @connector.delete_binding(binding)
          end
        end
        @connector.save_element_bindings(service_component, [uri], @urns['service-components'], "service component")
      end

      def find_service_component_uri(service_component)
        @connector.find_element_bindings(service_component, @urns['service-components'])
      end

      def save_business(key, name, description = nil)
        @connector.authorize
        @connector.save_business(key, name, description)
      end

      def get_business(key)
        @connector.get_business(key)
      end

      def find_businesses(pattern = nil)
        pattern = pattern.nil? ? '%' : "%#{pattern}%"

        @connector.find_business(pattern)
      end

      def delete_business(key)
        @connector.authorize
        @connector.delete_business(key)
      end

      def business_eq?(business, comparison)
        business == "#{@urns['domains']}#{comparison}"
      end    
    end
  end
end
