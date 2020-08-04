require 'erubi'
require 'rouge'
require 'redcarpet'
require 'tmpdir'

require 'rtfdoc/version'

module RTFDoc
  class AttributesComponent
    def initialize(raw_attrs, title)
      @attributes = YAML.load(raw_attrs)
      @title      = title
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

    def emphasis(text)
      "<em>#{text}</em>"
    end

    def double_emphasis(text)
      "<strong>#{text}</strong>"
    end

    def paragraph(text)
      "<p>#{text}</p>"
    end

    def header(text, level)
      if level == 4
        %(<div class="header-table">#{text}</div>)
      else
        "<h#{level}>#{text}</h#{level}>"
      end
    end

    def table(header, body)
      <<-HTML
        <div class="table-wrapper">
          <div class="header-table">#{@table_title}</div>
          <table>
            <thead></thead>
            <tbody>#{body}</tbody>
          </table>
        </div>
      HTML
    ensure
      @table_title = nil
    end

    def table_row(content)
      content.empty? ? nil : "<tr>#{content}</tr>"
    end

    def table_cell(content, alignment)
      if !alignment
        @table_title = content unless content.empty?
        return
      end

      c = case alignment
      when 'left'   then 'definition'.freeze
      when 'right'  then 'property'.freeze
      end

      "<td class=\"cell-#{c}\">#{content}</td>"
    end

    def block_html(raw_html)
      raw_html
    end

    def codespan(code)
      "<code>#{code}</code>"
    end

    def block_code(code, language)
      if language == 'attributes' || language == 'parameters'
        AttributesComponent.new(code, language).output
      elsif language == 'response'
        format_code('RESPONSE', code)
      elsif language == 'title_and_code'
        title, _code = code.split("\n", 2)
        title ||= 'RESPONSE'
        format_code(title, _code)
      end
    end

    private def format_code(title, code)
      <<-HTML
      <div class="section-response">
        <div class="response-topbar">#{title}</div>
        <pre><code>#{rouge_formatter.format(rouge_lexer.lex(code.strip))}</code></pre>
      </div>
      HTML
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

  module RenderAsSection
    def self.included(other)
      other.attr_accessor(:include_show_button)
    end

    template = Erubi::Engine.new(File.read(File.expand_path('../src/section.erb', __dir__)))
    module_eval <<-RUBY
      define_method(:output) { #{template.src} }
    RUBY

    def content_to_html
      RTFDoc.markdown_to_html(@content)
    end

    def example_to_html
      @example ? RTFDoc.markdown_to_html(@example) : nil
    end
  end

  module Anchorable
    def anchor(content, class_list: nil)
      %(<a href="##{anchor_id}") <<
        (class_list ? %( class="#{class_list}") : '') <<
        "><span>#{content}</span></a>"
    end
  end

  class Section
    include RenderAsSection
    include Anchorable

    attr_reader :name, :method, :path

    def initialize(name, raw_content, resource: nil)
      @name     = name
      @resource = resource
      metadata  = nil

      if raw_content.start_with?('---')
        idx = raw_content.index('---', 4)
        raise 'bad format' unless idx
        parse_metadata(YAML.load(raw_content.slice!(0, idx + 3)))
      end

      raise 'missing metadata' if resource && !meta_section? && !@path && !@method

      @content, @example = raw_content.split('$$$')
    end

    def id
      @id ||= name
    end

    def anchor_id
      @resource ? "#{@resource}-#{id}" : id
    end

    def resource_name
      @resource
    end

    def menu_output
      "<li>#{anchor(menu_title)}</li>"
    end

    def signature
      anchor(sig)
    end

    def example_to_html
      res = super
      @resource && res && !meta_section? ? res.sub('RESPONSE', sig) : res
    end

    private

    def sig
      @sig ||= <<-HTML.strip!
        <div class="endpoint-def">
          <div class="method method__#{method.downcase}">#{method.upcase}</div>
          <div class="path">#{path}</div>
        </div>
      HTML
    end

    def meta_section?
      name == 'desc' || name == 'object'
    end

    def menu_title
      @menu_title || name.capitalize
    end

    def parse_metadata(hash)
      @id           = hash['id']
      @menu_title   = hash['menu_title']
      @path         = hash['path']
      @method       = hash['method']
    end
  end

  class ResourceDesc
    include RenderAsSection
    include Anchorable

    attr_reader :resource_name

    def initialize(resource_name, content)
      @resource_name  = resource_name
      @content        = content
    end

    def name
      'desc'
    end

    def anchor_id
      "#{resource_name}-desc"
    end

    def generate_example(sections)
      endpoints   = sections.reject { |s| s.name == 'desc' || s.name == 'object' }
      signatures  = endpoints.each_with_object("") do |e, res|
        res << %(<div class="resource-sig">#{e.signature}</div>)
      end

      @example = <<-HTML
      <div class="section-response">
        <div class="response-topbar">ENDPOINTS</div>
        <div class="section-endpoints">#{signatures}</div>
      </div>
      HTML
    end

    def example_to_html
      @example
    end
  end

  class Resource
    DEFAULT = %w[desc object index show create update destroy]

    def self.build(name, paths, endpoints: nil)
      endpoints ||= DEFAULT
      desc = nil

      sections = endpoints.each_with_object([]) do |endpoint, res|
        filename = paths[endpoint]
        next unless filename

        content = File.read(filename)

        if endpoint == 'desc'
          desc = ResourceDesc.new(name, content)
          res << desc
        else
          res << Section.new(endpoint, content, resource: name)
        end
      end

      desc&.generate_example(sections)
      Resource.new(name, sections)
    end

    attr_reader :name, :sections

    def initialize(name, sections)
      @name, @sections = name, sections
    end

    def output
      head, *tail = sections
      head.include_show_button = true

      inner = sections.map(&:output).join("\n")
      %(<section class="head-section">#{inner}</section>)
    end

    def menu_output
      head, *tail = sections
      <<-HTML
        <li data-anchor="#{name}">
          #{head.anchor(name.capitalize, class_list: 'expandable')}
          <ul>#{tail.map(&:menu_output).join}</ul>
        </li>
      HTML
    end
  end

  class Generator
    attr_reader :renderer, :config

    def initialize(config_path)
      @config       = YAML.load_file(config_path)
      @content_dir  = @config['content_dir']
      @parts        = {}
    end

    def run
      tree = build_content_tree

      nodes = config['resources'].map do |rs|
        if rs.is_a?(Hash)
          name, endpoints = rs.each_pair.first
          paths = tree[name]
          Resource.build(name, paths, endpoints: endpoints)
        else
          paths = tree[rs]
          paths.is_a?(Hash) ? Resource.build(rs, paths) : Section.new(rs, File.read(paths))
        end
      end

      out = File.new("#{Dir.tmpdir}/rtfdoc_output.html", 'w')
      out.write(Template.new(nodes).output)
      out.close
    end

    private

    def build_content_tree
      tree        = {}
      slicer      = (@content_dir.length + 1)..-1
      ext_slicer  = -3..-1

      Dir.glob("#{@content_dir}/**/*.md").each do |path|
        str       = path.slice(slicer)
        parts     = str.split('/')
        filename  = parts.pop
        filename.slice!(ext_slicer)

        leaf = parts.reduce(tree) { |h, part| h[part] || h[part] = {} }
        leaf[filename] = path
      end

      tree
    end
  end

  def self.renderer
    @renderer ||= Redcarpet::Markdown.new(Renderer, {
      underline:            true,
      space_after_headers:  true,
      fenced_code_blocks:   true,
      no_intra_emphasis:    true,
      tables:               true
    })
  end

  def self.markdown_to_html(text)
    renderer.render(text)
  end
end
