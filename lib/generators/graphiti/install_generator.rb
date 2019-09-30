require_relative "generator_mixin"

module Graphiti
  class InstallGenerator < ::Rails::Generators::Base
    include GeneratorMixin
    source_root File.expand_path("templates", __dir__)

    class_option :'api-namespace',
      type: :string,
      default: "/api/v1",
      desc: "Override namespace for API controller & routes"

    class_option :'omit-comments',
      type: :boolean,
      default: false,
      aliases: ["-c"],
      desc: "Generate without documentation comments"

    class_option :'namespace-controllers',
      type: :boolean,
      default: false,
      aliases: ["-n"],
      desc: "Generated controllers will be namespaced"

    desc "This generator boostraps graphiti"
    def install
      to = File.join("app/resources", "application_resource.rb")
      template("application_resource.rb.erb", to)

      if namespace_controllers?
        to = File.join(
          "app/controllers",
          (controller_namespaces_path if namespace_controllers?),
          "graphiti_controller.rb"
        )
        template("graphiti_controller.rb.erb", to)
      else
        inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::API\n" do
          app_controller_code
        end

        inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
          app_controller_code
        end
      end

      inject_into_file "config/application.rb", after: "Rails::Application\n" do
        <<-'RUBY'
    # In order for Graphiti to generate links, you need to set the routes host.
    # When not explicitly set, via the HOST env var, this will fall back to
    # the rails server settings.
    # Rails::Server is not defined in console or rake tasks, so this will only
    # use those defaults when they are available.
    routes.default_url_options[:host] = ENV.fetch('HOST') do
      if defined?(Rails::Server)
        argv_options = Rails::Server::Options.new.parse!(ARGV)
        "http://#{argv_options[:Host]}:#{argv_options[:Port]}"
      end
    end
        RUBY
      end

      inject_into_file "spec/rails_helper.rb", after: /RSpec.configure.+^end$/m do
        "\n\nGraphitiSpecHelpers::RSpec.schema!"
      end

      insert_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
          <<-STR
  scope path: ApplicationResource.endpoint_namespace, defaults: { format: :jsonapi }\
#{", module: \"#{clean_namespace}\"" if namespace_controllers?} do
    # your routes go here\
#{"\n\t\tmount VandalUi::Engine, at: '/vandal'" if defined?(VandalUi)}
  end
          STR
      end
    end

    private

    def omit_comments?
      @options["omit-comments"]
    end

    def app_controller_code
      str = ""
      if defined?(::Responders)
        str << "  include Graphiti::Rails::Responders\n"
      end
      str
    end
  end
end
