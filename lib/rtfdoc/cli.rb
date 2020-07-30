require 'thor'
require 'rtfdoc/generators/bootstrap'

module RTFDoc
  class CLI < Thor
    desc "bootstrap NAME", "scaffold a new project"
    def bootstrap(name)
      subcommand 'boostrap', Bootstrap
    end
  end
end
