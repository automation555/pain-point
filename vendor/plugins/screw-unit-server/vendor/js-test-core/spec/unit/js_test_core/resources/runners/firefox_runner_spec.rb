require File.expand_path("#{File.dirname(__FILE__)}/../../../unit_spec_helper")

module JsTestCore
  module Resources
    describe Runners::FirefoxRunner do
      attr_reader :runner, :request, :response, :driver, :suite_id
      
      before do
        Thread.current[:connection] = connection
        @driver = "Selenium Driver"
        @suite_id = 12345
        stub(Selenium::SeleniumDriver).new('localhost', 4444, '*firefox', 'http://0.0.0.0:8080') do
          driver
        end
      end

      describe ".resume" do
        describe "when there is a runner for the passed in suite_id" do
          before do
            @request = Rack::Request.new( Rack::MockRequest.env_for('/runners/firefox') )
            @response = Rack::Response.new
            @runner = Runners::FirefoxRunner.new
            stub(Thread).start.yields
            
            stub(driver).start
            stub(driver).open
            stub(driver).session_id {suite_id}
            stub(driver).stop
            stub(EventMachine).send_data
            stub(EventMachine).close_connection

            runner.post(request, response)
            runner.suite_id.should == suite_id
          end

          it "removes and finalizes the instance that has the suite_id" do
            mock.proxy(runner).finalize("Browser output")
            Runners::FirefoxRunner.send(:instances)[suite_id].should == runner
            Runners::FirefoxRunner.resume(suite_id, "Browser output")
            Runners::FirefoxRunner.send(:instances)[suite_id].should be_nil
          end
        end

        describe "when there is not a runner for the passed in suite_id" do
          it "does nothing" do
            lambda do
              Runners::FirefoxRunner.resume("invalid", "nothing happens")
            end.should_not raise_error
          end
        end
      end

      describe "#post" do
        attr_reader :firefox_profile_path
        before do
          @request = Rack::Request.new( Rack::MockRequest.env_for('/runners/firefox') )
          @response = Rack::Response.new
          @runner = Runners::FirefoxRunner.new
          stub(Thread).start.yields
        end

        it "keeps the connection open" do
          stub(driver).start
          stub(driver).open
          stub(driver).session_id {suite_id}
          dont_allow(EventMachine).send_data
          dont_allow(EventMachine).close_connection
          runner.post(request, response)

          response.body.should be_empty
        end
        
        describe "when a selenium_host parameter is passed into the request" do
          before do
            request['selenium_host'] = "another-machine"
            stub(driver).start
            stub(driver).open
            stub(driver).session_id {suite_id}
          end

          it "starts the Selenium Driver with the passed in selenium_host" do
            mock(Selenium::SeleniumDriver).new('another-machine', 4444, '*firefox', 'http://0.0.0.0:8080') do
              driver
            end
            runner.post(request, response)
          end
        end

        describe "when a selenium_host parameter is not passed into the request" do
          before do
            request['selenium_host'].should be_nil
            stub(driver).start
            stub(driver).open
            stub(driver).session_id {suite_id}
          end

          it "starts the Selenium Driver from localhost" do
            mock(Selenium::SeleniumDriver).new('localhost', 4444, '*firefox', 'http://0.0.0.0:8080') do
              driver
            end
            runner.post(request, response)
          end
        end

        describe "when a selenium_port parameter is passed into the request" do
          before do
            request['selenium_port'] = "4000"
            stub(driver).start
            stub(driver).open
            stub(driver).session_id {suite_id}
          end

          it "starts the Selenium Driver with the passed in selenium_port" do
            mock(Selenium::SeleniumDriver).new('localhost', 4000, '*firefox', 'http://0.0.0.0:8080') do
              driver
            end
            runner.post(request, response)
          end
        end

        describe "when a selenium_port parameter is not passed into the request" do
          before do
            request['selenium_port'].should be_nil
            stub(driver).start
            stub(driver).open
            stub(driver).session_id {suite_id}
          end

          it "starts the Selenium Driver from localhost" do
            mock(Selenium::SeleniumDriver).new('localhost', 4444, '*firefox', 'http://0.0.0.0:8080') do
              driver
            end
            runner.post(request, response)
          end
        end

        describe "when a spec_url is passed into the request" do
          before do
            request['spec_url'] = "http://another-host:8080/specs/subdir"
          end

          it "runs Selenium with the passed in host and part to run the specified spec suite in Firefox" do
            mock(Selenium::SeleniumDriver).new('localhost', 4444, '*firefox', 'http://another-host:8080') do
              driver
            end
            mock(driver).start
            mock(driver).open("http://another-host:8080/specs/subdir")
            mock(driver).session_id {suite_id}

            runner.post(request, response)
          end
        end

        describe "when a spec_url is not passed into the request" do
          before do
            request['spec_url'].should be_nil
            mock(Selenium::SeleniumDriver).new('localhost', 4444, '*firefox', 'http://0.0.0.0:8080') do
              driver
            end
          end

          it "uses Selenium to run the entire spec suite in Firefox" do
            mock(driver).start
            mock(driver).open("http://0.0.0.0:8080/specs")
            mock(driver).session_id {suite_id}

            runner.post(request, response)
          end
        end
      end

      describe "#finalize" do
        before do
          @request = Rack::Request.new( Rack::MockRequest.env_for('/runners/firefox') )
          @response = Rack::Response.new
          @runner = Runners::FirefoxRunner.new
          stub(driver).start
          stub(driver).open
          stub(driver).session_id {suite_id}
          runner.post(request, response)
        end

        it "kills the browser, sends the response body, and close the connection" do
          mock(driver).stop
          data = ""
          stub(EventMachine).send_data do |signature, data, data_length|
            data << data
          end
          mock(connection).close_connection_after_writing

          runner.finalize("The text")
          data.should include("The text")
        end
      end
    end
  end
end
