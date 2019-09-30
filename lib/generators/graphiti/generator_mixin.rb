module Graphiti
  module GeneratorMixin
    def prompt(header: nil, description: nil, default: nil)
      say(set_color("\n#{header}", :magenta, :bold)) if header
      say("\n#{description}") if description
      answer = ask(set_color("\n(default: #{default}):", :magenta, :bold))
      answer = default if answer.blank? && default != "nil"
      say(set_color("\nGot it!\n", :white, :bold))
      answer
    end

    def api_namespace
      @api_namespace ||= (graphiti_config["namespace"] || @options["namespace"])
    end

    def namespace_controllers?
      @namespace_controllers ||= (graphiti_config["namespace-controllers"] || @options["namespace-controllers"])
    end

    def clean_namespace
      api_namespace.gsub(/^\/|\/$/,"")
    end

    def controller_namespaces_path
      clean_namespace.split("/")
    end

    def controller_modules
      if namespace_controllers?
        output = ""
        controller_namespaces_path.each do |mod|
          output += mod.capitalize + "::"
        end
        output
      end
    end

    def actions
      @options["actions"] || %w[index show create update destroy]
    end

    def actions?(*methods)
      methods.any? { |m| actions.include?(m) }
    end

    def graphiti_config
      File.exist?(".graphiticfg.yml") ? YAML.load_file(".graphiticfg.yml") : {}
    end

    def update_config!(attrs)
      config = graphiti_config.merge(attrs)
      File.open(".graphiticfg.yml", "w") { |f| f.write(config.to_yaml) }
    end
  end
end
