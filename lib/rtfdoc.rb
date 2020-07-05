require 'bundler/setup'
Bundler.require(:default)

module RTFDoc

  module Renderable
    def initialize(renderer)
      @renderer = renderer
    end

    def render_markdown(text)
      @renderer.render(text)
    end
  end

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
    attr_reader :rouge_formatter, :rouge_lexer

    def initialize(*args)
      super
      @rouge_formatter  = Rouge::Formatters::HTML.new
      @rouge_lexer      = Rouge::Lexers::JSON.new
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
      elsif language == 'response'
        <<-HTML
        <div class="section-response">
          <div class="response-topbar">RESPONSE</div>
          <pre><code>#{rouge_formatter.format(rouge_lexer.lex(code.strip))}</code></pre>
        </div>
        HTML
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

  class Section
    include Renderable

    def initialize(raw_content, filename, renderer)
      if raw_content.start_with?('---')
        idx = raw_content.index('---', 4)
        raise 'bad format' unless idx

        @metadata = raw_content.slice!(0, idx)
        @content, @example = raw_content.split('$$$')
        @content.slice!(0, 3) # remove leading `---` left
      else
        @content, @example = raw_content.split('$$$')
      end

      super(renderer)
      parse_metadata(filename)
    end

    def content_to_html
      render_markdown(@content)
    end

    def example_to_html
      @example ? render_markdown(@example.strip) : nil
    end

    template = Erubi::Engine.new(File.read(File.expand_path('../src/section.erb', __dir__)))
    class_eval <<-RUBY
      define_method(:output) { #{template.src} }
    RUBY

    private

    def parse_metadata(filename)
      if defined?(@metadata)
        meta    = YAML.load(@metadata)
        @id     = meta['id']
        @title  = meta['title']
      else
        @id = @title = filename
      end
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

    text    = File.read('content/intro/body.md')
    section = Section.new(text, nil, markdown)
    content = section.output

    out     = File.new(File.expand_path('../src/output.html', __dir__), 'w')
    out.write(Template.new(content).output)
    out.close
  end
end
