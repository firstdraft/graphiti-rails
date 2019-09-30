require_relative "generator_mixin"

module Graphiti
  class RelationshipsGenerator < ::Rails::Generators::NamedBase
    include GeneratorMixin

    def generate_relationships
      p class_name
    end
  end
end
