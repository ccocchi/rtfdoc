require 'thor'
require 'rtfdoc/generators/bootstrap'

module RTFDoc
  class CLI < Thor
    include Thor::Actions

    def self.exit_on_failure?
      true
    end

    register(Bootstrap, 'bootstrap', 'bootstrap NAME', "Scaffolds a new project")

    desc 'convert', 'Convert your markdown content into HTML'
    option 'config', aliases: '-c', type: 'string', required: true
    def convert
      ::RTFDoc::Generator.new(options[:config]).run
    end

    source_root(File.expand_path('../../', __dir__))

    desc 'install', 'Copy the latest version of the assets source in your project'
    def install
      directory 'src', 'src', exclude_pattern: /\.erb\Z/
    end
  end
end
