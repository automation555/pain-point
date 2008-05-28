require File.expand_path("#{File.dirname(__FILE__)}/../selenium_helper")

describe "A User on the home page" do
  before do
    open "/"
  end

  it "displays all of the PainPoints" do
    pain_points = PainPoint.find(:all)
    pain_points.should_not be_empty
    pain_points.each do |pain_point|
      element("id=vote_#{pain_point.id}").assert_contains(pain_point.name)
    end
  end

  describe "clicking the up vote" do
    describe "when logged in" do
      attr_reader :user
      before do
        @user = users(:quentin)
        element("link=Login").click
        element("name=login").type(user.login)
        element("name=password").type('test')
        element("name=commit").click
      end

      it "increments the vote count by 1" do
        element("css=.score").assert_contains('0')
        element("css=.up").click
        element("css=.score").assert_contains('1')
      end
    end

    describe "when not logged in" do
      describe "then logging in" do
        attr_reader :user
        before do
          element("css=.score").assert_contains('0')
          click "css=.up"
          pending "Client side will handle login" do
            assert_location_ends_with new_session_path
          end
          @user = users(:quentin)
          element("link=Login").click
          element("name=login").type(user.login)
          element("name=password").type('test')
          element("name=commit").click
        end

        it "redirects to PainPoint page and sets the score up by 1" do
          pending "Apply vote when logging in"
          wait_for do
            URI.parse(get_location).path == '/'
          end
          element("css=.score").assert_contains('1')
        end
      end
    end
  end
end