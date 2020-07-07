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

    def header(text, level)
      "<h#{level}>#{text}</h#{level}>"
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
    def initialize(sections)
      @content = sections.map(&:output).join
      @menu_content = sections.map(&:menu_output).join
    end

    def output
      template = Erubi::Engine.new(File.read(File.expand_path('../src/index.html.erb', __dir__)))
      eval(template.src)
    end
  end

  class Section
    include Renderable

    attr_reader :id, :menu_title

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

    def menu_output
      %(<li><a href="##{id}">#{menu_title}</a></li>)
    end

    private

    def parse_metadata(filename)
      if defined?(@metadata)
        meta    = YAML.load(@metadata)
        @id     = meta['id']
        @menu_title  = meta['menu_title']
      else
        @id = @menu_title = filename
      end
    end
  end

  def self.extract_filename(str)
    i = str.rindex('/')
    str.slice(i + 1, str.length - i - 4)
  end

  def self.generate
    markdown = Redcarpet::Markdown.new(Renderer, {
      underline:            true,
      strikethrough:        true,
      space_after_headers:  true,
      fenced_code_blocks:   true,
      no_intra_emphasis:    true
    })

    config = YAML.load_file('content/config.yml')

    hash = Dir.glob('content/**/*.md').each_with_object({}) do |path, res|
      filename  = extract_filename(path)
      text      = File.read(path)
      res[filename] = Section.new(text, filename, markdown)
    end

    sections = hash.values_at *config['resources']

    out     = File.new(File.expand_path('../src/output.html', __dir__), 'w')
    out.write(Template.new(sections).output)
    out.close
  end
end
