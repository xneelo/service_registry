require 'uri'
require 'service_registry'
require 'json'

module ServiceRegistry
  module Test
    class TfaServiceRegistry < ServiceRegistry::Providers::JSendProvider
      attr_writer :authorized

      def initialize
        @tfa_uri = "http://localhost:8080"
        urns = { 'base' => ServiceRegistry::HETZNER_BASE_URN,
                 'company' => ServiceRegistry::HETZNER_URN,
                 'domains' => ServiceRegistry::HETZNER_DOMAINS_URN,
                 'services' => ServiceRegistry::HETZNER_SERVICES_URN,
                 'service-components' => ServiceRegistry::HETZNER_SERVICE_COMPONENTS_URN}
        @juddi = ServiceRegistry::Providers::JUDDIProvider.new(urns)
        @juddi.set_uri(@tfa_uri)
        @authorized = true
        @credentials = { 'username' => 'uddi', 'password' => 'uddi' }
      end

      def fix
        @juddi.set_uri(@tfa_uri)
        @broken = false
      end

      def break
        @juddi.set_uri("http://127.0.0.1:9992")
        @broken = true
      end

      # ---- services ----

      def register_service(service)
        authorize
        return fail('no service identifier provided') if service.nil? or service['name'].nil?
        return fail('invalid service identifier provided') if ((not service.is_a? Hash) or (service['name'].strip == ""))
        return fail('service already exists') if is_registered?(service_registered?(service['name']))

        description = []
        description << service ['description'] if service['description']
        description << service ['meta'] if service['meta']

        result = @juddi.save_service(service['name'], description, service['definition'])
        return fail('invalid service identifier provided') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        success('service registered')

        rescue => ex
          fix if @broken
          fail('failure registering service')
      end

      def service_registered?(service)
        result = @juddi.find_services(service)
        registered = false
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'services')
          result['data']['services'].each do |service_key, description|
            registered = (service.downcase == service_key.downcase)
          end
        end
        success_data({'registered' => registered})
      end

      def deregister_service(service)
        authorize
        return fail('no service identifier provided') if service.nil?
        return fail('invalid service identifier provided') if service.strip == ""
        return success('unknown service') if not is_registered?(service_registered?(service))
        result = @juddi.delete_service(service)
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        return fail('invalid service identifier provided') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        success('service deregistered')

      rescue => ex
        fix if @broken
        fail('failure deregistering service')        
      end

      # ---- service definition ----

      def register_service_definition(service, definition)
        authorize 
        return fail('no service identifier provided') if service.nil?
        return fail('invalid service identifier provided') if (service.strip == "")
        return success('unknown service identifier provided') if not is_registered?(service_registered?(service))
        return fail('no service definition provided') if definition.nil?
        return fail('invalid service definition provided') if not definition.include?("wadl")

        result = @juddi.get_service(service)
        service = result['data']
        service['definition'] = definition
        result = @juddi.save_service(service['name'], service['description'], service['definition'])
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')        
        return fail('invalid service identifier provided') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        success('service definition registered')
      rescue => ex
        fix if @broken
        fail('failure registering service definition')           
      end

      def service_definition_for_service(service)
        return fail('no service provided') if service.nil?
        return fail('invalid service identifier provided') if (service.strip == "")
        return success('unknown service') if not is_registered?(service_registered?(service))
        result = @juddi.get_service(service)['data']
        return fail('invalid service identifier provided') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        return fail('service has no definition') if (result['definition'].nil?) or (result['definition'] == "")
        return success_data({'definition' => result['definition']}) if (not result.nil?) and (not result['definition'].nil?)
      end

      def deregister_service_definition(service)
        authorize
        return fail('no service provided') if service.nil?
        return fail('invalid service identifier provided') if (service.strip == "")
        return success('unknown service') if not is_registered?(service_registered?(service))
        result = @juddi.get_service(service)
        service = result['data']
        service['definition'] = ""
        result = @juddi.save_service(service['name'], service['description'], service['definition'])
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        success('service definition deregistered')
      end

      # ---- domain perspectives ----      

      def reset_domain_perspectives
        authorize
        return if not @authorized
        result = list_domain_perspectives
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'domain_perspectives') 
          result['data']['domain_perspectives'].each do |domain_perspective|
            @juddi.delete_business(domain_perspective)
          end
        end
      end

      def list_domain_perspectives
        result = @juddi.find_businesses
        result['data']['domain_perspectives'] = []

        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'businesses')
          result['data']['businesses'].each do |business, description|
            result['data']['domain_perspectives'] << business
          end
        end
        result

      rescue => ex
        fix if @broken
        fail('failure listing domain perspectives')          
      end

      def domain_perspective_registered?(domain_perspective)
        result = @juddi.find_businesses(domain_perspective)
        registered = false
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'businesses')
          result['data']['businesses'].each do |business, description|
            registered = (domain_perspective.downcase == business.downcase)
          end
        end
        success_data({'registered' => registered})
      end

      def register_domain_perspective(domain_perspective)
        authorize

        return fail('no domain perspective provided') if domain_perspective.nil?
        return fail('invalid domain perspective') if (domain_perspective and domain_perspective.strip == "")
        return fail('domain perspective already exists') if is_registered?(domain_perspective_registered?(domain_perspective))

        result = @juddi.save_business(domain_perspective)

        return fail('invalid domain perspective') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')

        success('domain perspective registered')

      rescue => ex
        fix if @broken
        fail('failure registering domain perspective')     
      end

      def deregister_domain_perspective(domain_perspective)
        authorize
        return fail('no domain perspective provided') if domain_perspective.nil?
        return fail('invalid domain perspective provided') if domain_perspective.strip == ""

        return fail('domain perspective unknown') if not is_registered?(domain_perspective_registered?(domain_perspective))
        # return fail('domain perspective has associations') if does_domain_perspective_have_service_components_associated?(domain_perspective)

        result = @juddi.delete_business(domain_perspective)
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        return fail('invalid domain perspective provided') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        success('domain perspective deregistered')

      rescue => ex
        fix if @broken
        fail('failure deregistering domain perspective')        
      end

      # ---- service components ----
      def list_service_components(domain_perspective = nil)
        result = @juddi.find_service_components
        service_components = ServiceRegistry::Providers::JSendProvider::has_data?(result, 'services') ? result['data']['services'] : {}

        if (domain_perspective)
          list = service_components
          service_components.each do |service_component|
            list.delete(service_component) if false #check service component - domain perspective association here by businessKey
          end
          service_components = list
        end
        result['data']['service_components'] = []
        service_components.each do |service_component, description|
          result['data']['service_components'] << service_component
        end
        result['data'].delete('services')
        result

      rescue => ex
        fix if @broken
        fail('failure retrieving service components')           
      end

      def delete_all_service_components
        authorize
        return if not @authorized
        result = list_service_components
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'service_components') 
          result['data']['service_components'].each do |service_component, description|
            @juddi.delete_service_component(service_component)
          end
        end
      end

      def service_component_registered?(service_component)
        result = @juddi.find_service_components(service_component)
        registered = false
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'services')
          result['data']['services'].each do |service_key, description|
            registered = (service_component.downcase == service_key.downcase)
          end
        end
        success_data({'registered' => registered})
      end

      def register_service_component(service_component)
        authorize
        return fail('no service component identifier provided') if service_component.nil?
        return fail('invalid service component identifier') if service_component.strip == ""
        return fail('service component already exists') if is_registered?(service_component_registered?(service_component))

        result = @juddi.save_service_component(service_component)
        return fail('invalid service component identifier') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        success('service component registered')

        rescue => ex
          fix if @broken
          fail('failure registering service component')
      end

      def deregister_service_component(service_component)
         authorize
         return fail('no service component identifier provided') if service_component.nil?
         return fail('invalid service component identifier') if service_component.strip == ""
         return success('service component unknown') if not is_registered?(service_component_registered?(service_component))
         result = @juddi.delete_business(service_component)
         return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
         return fail('invalid service component identifier') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
         success('service component deregistered')

       rescue => ex
         fix if @broken
         fail('failure deregistering service component')        
      end

      def configure_service_component_uri(service_component, uri)
        authorize
        return fail('no service component provided') if service_component.nil?
        return fail('invalid service component identifier') if (service_component.strip == "")
        return fail('no URI provided') if uri.nil?
        return fail('invalid URI') if not (uri =~ URI::DEFAULT_PARSER.regexp[:UNSAFE]).nil?
        result = @juddi.save_service_component_uri(service_component, uri)
        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        return fail('invalid service component identifier or URI') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        success

       rescue => ex
         fix if @broken
         fail('failure configuring service component')
      end

      def service_component_uri(service_component)
        return fail('no service component provided') if service_component.nil?
        return fail('invalid service component identifier') if (service_component.strip == "")
        result = @juddi.find_service_component_uri(service_component)
        return fail('invalid service component identifier') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')
        uri = (ServiceRegistry::Providers::JSendProvider::has_data?(result, 'bindings') and (result['data']['bindings'].size > 0)) ? result['data']['bindings'].first[1]['access_point'] : nil
        result['data']['uri'] = uri
        result
      end   

      # ---- meta ----
      def configure_meta_for_service(service, meta)
        authorize

        return fail('no service provided') if service.nil?
        return fail('invalid service provided') if (service.strip == "")

        return fail('no meta provided') if meta.nil?
        return fail('invalid meta') if not meta.is_a?(Hash)

        descriptions = []
        detail = @juddi.get_service(service)['data']['description']
        detail.each do |desc|
          descriptions << desc if not description_is_meta?(desc)
        end

        descriptions << CGI.escape(meta.to_json)

        detail = @juddi.get_service(service)['data']
        detail['description'] = descriptions

        result = @juddi.save_service(detail['name'], detail['description'], detail['definition'])

        return fail('not authorized') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_authTokenRequired')
        return fail('invalid meta') if ServiceRegistry::Providers::JSendProvider::notifications_include?(result, 'E_invalidKeyPassed')

        success_data('meta updated', result['data'])
       rescue => ex
         fix if @broken
         fail('failure configuring service with meta')
      end

      def description_is_meta?(meta)
        JSON.parse(CGI.unescape(meta))
        true
      rescue => ex
        false
      end

      def meta_for_service(service)
        detail = @juddi.get_service(service)['data']
        if detail['description']
          detail['description'].each do |desc|
            return JSON.parse(CGI.unescape(desc)) if (description_is_meta?(desc))
          end
        end

        {}
      end

      # ---- search ----
      def check_dss(name)
        result = @dss.query(name)
        return false if result.nil? or result == 'error'
        result
      end

      def query_service_by_pattern(pattern)
        result = @juddi.find_services
        list = {}        
        if ServiceRegistry::Providers::JSendProvider::has_data?(result, 'services')
          result['data']['services'].each do |service, name|
            detail = @juddi.get_service(service)
            if ServiceRegistry::Providers::JSendProvider::has_data?(detail, 'description')
              found = false
              dss = nil
              detail['data']['description'].each do |description|
                found = true if (description and description.include?(pattern))
                dss = description.gsub("dss:", "").strip if (description and description.include?('dss:'))
              end
              list[service] = detail if ((dss and (@dss and check_dss(service))) or (not dss)) and found
            end
          end
        end
        
        success_data({ 'services' => list })
      end

      # ---- associations ----
      def associate_service_component_with_domain_perspective(domain_perspective, service_component)
      end

      def delete_domain_perspective_service_component_associations(domain_perspective)
      end

      private

      def authorize
        raise RuntimeError.new("Not available / properly initialized") if not available?['data']['available']
        @juddi.authenticate(@credentials['username'], @credentials['password']) if @authorized
        @juddi.authenticate('', '') if not @authorized
      end

      def is_registered?(result)
        ServiceRegistry::Providers::JSendProvider::has_data?(result, 'registered') and result['data']['registered']
      end
    end
  end
end