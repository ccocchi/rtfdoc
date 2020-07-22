require 'bundler/setup'
Bundler.require(:default)

module RTFDoc

  module Renderable
    def initialize(renderer)
      @renderer = renderer
    end

    def render_markdown(text)
      byebug if text == nil
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

  class Resource
    attr_reader :sections

    ORDER = %w[object index show create update destroy]

    def initialize(name)
      @name     = name
      @available_sections = {}
    end

    def finalize(o = nil)
      ensure_valid
      o ||= ORDER
      @available_sections['desc'].resource = self
      o.unshift('desc') unless o[0] == 'desc'

      @sections = @available_sections.values_at(*o).compact
    end

    def method_sections
      sections.slice(2..-1)
    end

    def append_section(s)
      @available_sections[s.filename] = s
    end

    def output
      sections.map(&:output).join("\n")
    end

    def menu_output
      ary  = sections.dup
      head = ary.shift

      <<-HTML
        <li>
          <a href="##{head.id}">#{head.menu_title}</a>
          <ul>
            #{ary.map(&:menu_output)}
          </ul>
        </li>
      HTML
    end

    private

    def ensure_valid
      raise ArgumentError, "missing desc.md for #{@name}"    unless @available_sections.key?('desc')
      raise ArgumentError, "missing object.md for #{@name}"  unless @available_sections.key?('object')
    end
  end

  class Section
    include Renderable

    def self.build(content, filename, renderer, resource = false)
      if resource && filename == 'desc'
        ResourceDesc.new(content, filename, renderer)
      else
        Section.new(content, filename, renderer)
      end
    end

    # Name of the resource section is part of
    # attr_reader :resource

    # Filename without the `md` extension
    attr_reader :filename

    attr_reader :id, :menu_title, :path, :method

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

      @filename = filename
      parse_metadata
    end

    def finalize # noop
    end

    template = Erubi::Engine.new(File.read(File.expand_path('../src/section.erb', __dir__)))
    class_eval <<-RUBY
      define_method(:output) { #{template.src} }
    RUBY

    def menu_output
      anchor(menu_title)
    end

    def signature
      sig = <<-HTML.strip!
        <div class="method method-#{method.downcase}">#{method.upcase}</div>
        <div class="path">#{path}</div>
      HTML

      anchor(sig)
    end

    private

    def content_to_html
      render_markdown(@content)
    end

    def example_to_html
      @example ? render_markdown(@example.strip) : nil
    end

    def anchor(content)
      %(<li><a href="##{id}">#{content}</a></li>)
    end

    def parse_metadata
      meta = defined?(@metadata) ? YAML.load(@metadata) : {}
      @id = meta['id'] || filename
      @menu_title  = meta['menu_title'] || filename
      @path = meta['path']
      @method = meta['method'] || conventional_method
    end

    def conventional_method
      case filename
      when 'create' then 'POST'
      when 'index', 'show' then 'GET'
      when 'update' then 'PUT'
      when 'destroy' then 'DELETE'
      else
        nil
      end
    end
  end

  class ResourceDesc < Section
    attr_reader :id, :menu_title, :content

    attr_accessor :resource

    def filename
      'desc'
    end

    def example_to_html
      <<-HTML.strip!
      <div class="section-response">
        <div class="response-topbar">ENDPOINTS</div>
        <div class="section-endpoints">#{endpoints_signatures}</div>
      </div>
      HTML
    end

    private

    def endpoints_signatures
      res = ""
      resource.method_sections.each do |s|
        res << %(<div class="resource-sig">#{s.signature}</div>)
      end

      res
    end
  end

  class Generator
    attr_reader :renderer, :config

    def initialize
      @renderer = Redcarpet::Markdown.new(Renderer, {
        underline:            true,
        strikethrough:        true,
        space_after_headers:  true,
        fenced_code_blocks:   true,
        no_intra_emphasis:    true
      })
      @config = YAML.load_file('config.yml')
      @parts  = {}
      @base_path = File.expand_path('../content', __dir__)
    end

    def run
      Dir.glob("#{@base_path}/**/*.md").each do |path|
        filename, dirname = stat(path)
        content = File.read(path)
        section = Section.build(content, filename, renderer, !dirname.nil?)

        if dirname
          @parts[dirname] ||= Resource.new(dirname)
          @parts[dirname].append_section(section)
        else
          @parts[filename] = section
        end
      end

      nodes = @config['resources'].map do |r|
        if r.is_a?(String)
          node = @parts.fetch(r)
          node.finalize
          node
        else
          res, order = res.each_pair[0]
          node = paths.fetch(res)
          raise "configuration error for #{res}" unless node.is_a?(Resource)
          node.finalize
          node
        end
      end

      out = File.new(File.expand_path('../src/output.html', __dir__), 'w')
      out.write(Template.new(nodes).output)
      out.close
    end

    private

    def stat(path)
      slicer  = (@base_path.length + 1)..-1
      str     = path.slice(slicer)
      i       = str.rindex('/') || -1
      dirname = i > 0 ? str.slice(0, i) : nil

      [str.slice(i + 1, str.length - i - 4), dirname]
    end
  end

  class Foo
    attr_reader :paths, :config

    def initialize(paths)
      @paths = paths
      @renderer = Redcarpet::Markdown.new(Renderer, {
        underline:            true,
        strikethrough:        true,
        space_after_headers:  true,
        fenced_code_blocks:   true,
        no_intra_emphasis:    true
      })
      @config = YAML.load_file('config.yml')

      @output = ""
      @menu_output = ""
    end

    DISPATCH = {
      'Section'   => :_visit_Section,
      'Resource'  => :_visit_Resource
    }

    def visit
      @config['resources'].each do |r|
        if r.is_a?(String)
          node = paths.fetch(r)
          dispatch(node)
        else
          res, order = res.each_pair[0]
          node = paths.fetch(res)
          raise unless node.is_a?(Resource)
          _visit_Resource(node, order)
        end
      end
    end

    private

    def dispatch(node, *args)
      send(DISPATCH[node.class.name], *args)
    end

    def _visit_Section(s, resource = nil)
      s.renderer = self.renderer
      output << s.output
    ensure
      s.renderer = nil
    end

    def _visit_Resource(r, order = nil)

    end

    def _visit_ResourceDesc(rd)

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
    config = YAML.load_file('config.yml')

    hash = Dir.glob('content/**/*.md').each_with_object({}) do |path, res|
      i = path.rindex('/')
      filename = path.slice(i + 1, path.length - i - 4)
      text = File.read(path)
      res[filename] = Section.new(text, filename, markdown)
    end

    sections = hash.values_at *config['resources']

    out = File.new(File.expand_path('../src/output.html', __dir__), 'w')
    out.write(Template.new(sections).output)
    out.close
  end
end
