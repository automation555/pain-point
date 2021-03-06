class Views::Layouts::Application < Erector::Widget
  def render
    html do
      head do
        title "Pain Point"
        js_files = [
          "jquery-1.2.3.js",
          "xmlbuilder",
          "json2",
          "jqModal",
          "models/pain_point",
          "views/login_view",
          "views/pain_point_view",
          "views/pain_points_view"
        ]
        javascript_include_tag(*js_files)
        stylesheet_link_tag 'application', 'jqModal', :cache => true
      end

      body do
        div do
          if current_user
            text "Logged in as #{current_user.login}"
            text " | "
            link_to "Logout", logout_path, :method => :delete
          else
            link_to "Login", login_path
          end
        end
        div flash[:notice], :class => "notice"
        div flash[:error], :class => "error"
        content
      end
    end
  end

  def content
    if @block
      instance_eval &block
    end
  end

  protected
  def current_user
    helpers.current_user
  end
end
