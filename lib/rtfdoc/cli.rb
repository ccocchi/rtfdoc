require 'thor'
require 'rtfdoc/generators/bootstrap'

module RTFDoc
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    register(Bootstrap, 'bootstrap', 'bootstrap NAME', "Scaffolds a new project")

    desc 'convert', 'Convert your markdown content into HTML'
    option 'config', aliases: '-c', type: 'string', required: true
    def convert
      ::RTFDoc::Generator.new(options[:config]).run
    end
  end
end
