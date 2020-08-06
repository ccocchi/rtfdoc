require 'thor/group'
require 'fileutils'

module RTFDoc
  class Bootstrap < Thor::Group
    include Thor::Actions

    argument :name, type: :string, desc: 'Name of the directory to bootstrap', required: true

    source_root(File.expand_path('../templates', __dir__))

    def create_root_directory
      FileUtils.mkdir_p(name)
    end

    def create_skeleton
      FileUtils.mkdir_p("#{name}/content")
      FileUtils.mkdir_p("#{name}/dist")
      copy_file('gitignore', "#{name}/.gitignore")
    end

    def create_gemfile
      template('Gemfile.erb', "#{name}/Gemfile")
    end

    def create_webpack_config
      template('package.json.erb', "#{name}/package.json")
      copy_file('webpack.config.js', "#{name}/webpack.config.js")
    end

    def create_config
      template('config.yml.erb', "#{name}/config.yml")
    end
  end
end
