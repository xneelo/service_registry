module ServiceRegistry
  module Providers
  	class Soap4JUDDIConnector
      include ServiceRegistry::Providers::JSender

      def initialize
        @soap_xml = ServiceRegistry::Providers::Soap4JUDDIXML.new
      end

      def authenticate(auth_user, auth_password)
        @auth_user = auth_user
        @auth_password =auth_password
      end

      def authorize(base_uri)
        @auth_token = '' # clear any existing token
        result = execute(build_authorization_request(base_uri)) do |res|
          @auth_token = (res.body.split('authtoken:')[1]).split('<')[0]
        end
        @auth_token
      end

      def request_soap(base_uri, version, service, request, attr = nil, &block)
        req = connection(base_uri, version, service)
        req.body = @soap_xml.soap_envelope(request, service, attr)
        execute(req) do |res|
          block.call(res)
        end
      end  

      def execute(req, &block)
        res = Net::HTTP.start(@uri.hostname, @uri.port) do |http|
          http.request(req)
        end

        jsend_result(res, block)
      end

      private

      def build_authorization_request(base_uri)
        req = connection(base_uri, 'security', 'get_authToken')
        auth = @soap_xml.element_with_value('get_authToken', '', {'userID' => @auth_user, 'cred' => @auth_password})
        req.body = @soap_xml.envelope_header_body(auth)
        req
      end

      def connection(base_uri, service, action)
        @uri = URI("#{base_uri}/juddiv3/services/#{service}")
        req = Net::HTTP::Post.new(@uri)
        req.content_type = @soap_xml.content_type
        req['SOAPAction'] = action
        req
      end      

      def jsend_result(res, block)
        case res
          when Net::HTTPSuccess
            return soap_success(res, block)
          else
            return fail(res.body)
          end       
      end

      def soap_success(res, block)
        result = block.call(res) if block
        return success_data(result) if result
        return success
      end  
  	end
  end
end
