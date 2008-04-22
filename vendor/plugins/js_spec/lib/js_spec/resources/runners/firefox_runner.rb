module JsSpec
  module Resources
    class Runners
      class FirefoxRunner
        class << self
          def resume(guid, text)
            runner = instances.delete(guid)
            runner.finalize(text)
          end

          def register_instance(runner)
            instances[runner.guid] = runner
          end

          protected
          def instances
            @instances ||= {}
          end
        end

        include FileUtils
        attr_reader :guid, :profile_dir, :request, :response, :connection, :driver

        def initialize(request, response)
          profile_base = "#{::Dir.tmpdir}/js_spec/firefox"
          mkdir_p profile_base
          @profile_dir = "#{profile_base}/#{Time.now.to_i}"
          @guid = Guid.new.to_s
          @request = request
          @response = response
          @connection = Server.connection
        end

        def post(request, response)
          FirefoxRunner.register_instance self
          spec_url = (request && request['spec_url']) ? request['spec_url'] : spec_suite_url
          parsed_spec_url = URI.parse(spec_url)
          @driver = Selenium::SeleniumDriver.new(
            request['selenium_host'] || 'localhost',
            (request['selenium_port'] || 4444).to_i,
            '*firefox',
            "#{parsed_spec_url.scheme}://#{parsed_spec_url.host}:#{parsed_spec_url.port}"
          )
          driver.start
          Thread.start do
            url = "#{spec_url}?guid=#{guid}"
            driver.open(url)
          end
          response.status = 200
        end

        def finalize(text)
          driver.stop
          response.body = text
          connection.send_body(response)
        end

        protected

        def spec_suite_url
          "#{Server.root_url}/specs"
        end
      end
    end
  end
end