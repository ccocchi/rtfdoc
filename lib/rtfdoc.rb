require 'bundler/setup'
Bundler.require(:default)

module RTFDoc

  class AttributesComponent
    def initialize(raw_attrs)
      @attributes = YAML.load(raw_attrs)
    end

    template = Erubi::Engine.new(File.read(File.expand_path('../src/attributes.erb', __dir__)))
    class_eval <<-RUBY
      define_method(:output) { #{template.src} }
    RUBY
  end

  class Renderer < Redcarpet::Render::Base
    def doc_header
      <<-HTML.strip
        <section id="introduction" class="head-section">
          <div class="section-divider"></div>
          <div class="section-area">
            <div class="section-body">
      HTML
    end

    def doc_footer
      <<-HTML.strip
          </div>
        </div>
        <div class="section-example"></div>
      </section>
      HTML
    end

    def paragraph(text)
      "<p>#{text}</p>"
    end

    def block_html(raw_html)
      raw_html
    end

    def block_code(code, language)
      if language == 'attributes'
        AttributesComponent.new(code).output
      end
    end
  end

  class Template
    def initialize(content)
      @content = content
    end

    def output
      template = Erubi::Engine.new(File.read(File.expand_path('../src/index.html.erb', __dir__)))
      eval(template.src)
    end
  end

  def self.generate
    markdown = Redcarpet::Markdown.new(Renderer, {
      underline:            true,
      strikethrough:        true,
      space_after_headers:  true,
      fenced_code_blocks:   true,
      no_intra_emphasis:    true
    })

    md      = File.read('content/intro/body.md')
    content = markdown.render(md)

    out     = File.new(File.expand_path('../src/output.html', __dir__), 'w')
    out.write(Template.new(content).output)
    out.close
  end
end
