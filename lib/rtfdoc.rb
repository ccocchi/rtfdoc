require 'erubi'
require 'rouge'
require 'redcarpet'
require 'tmpdir'

require 'rtfdoc/version'

module RTFDoc
  class AttributesComponent
    # Needed because we can't call the same rendered within itself.
    def self.private_renderer
      @renderer ||= Redcarpet::Markdown.new(::RTFDoc::Renderer, {
        underline:            true,
        space_after_headers:  true,
        fenced_code_blocks:   true,
        no_intra_emphasis:    true
      })
    end

    def initialize(raw_attrs, title)
      @attributes = YAML.load(raw_attrs)
      @title      = title
    end

    template = Erubi::Engine.new(File.read(File.expand_path('../src/attributes.erb', __dir__)))
    class_eval <<-RUBY
      define_method(:output) { #{template.src} }
    RUBY

    def to_html(text)
      self.class.private_renderer.render(text) if text
    end
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
    attr_reader :app_name, :page_title

    def initialize(nodes, config)
      @content      = nodes.flat_map(&:output).join
      # @menu_content = nodes.map(&:menu_output).join
      @app_name     = config['app_name']
      @page_title   = config['title']

      generate_grouped_menu_content(nodes)
    end

    def output
      template = Erubi::Engine.new(File.read(File.expand_path('../src/index.html.erb', __dir__)))
      eval(template.src)
    end

    private

    # Transform a list of nodes into a list of groups. If all nodes already are groups, it will
    # return the same list. Otherwise, it will build group from consecutives single resources.
    def generate_grouped_menu_content(nodes)
      i   = 0
      res = []

      while i < nodes.length
        node = nodes[i]
        if node.is_a?(Group)
          res << node
          i += 1
        else
          inner = []
          j = i
          while node && !node.is_a?(Group)
            inner << node
            j += 1
            node = nodes[j]
          end

          res << Group.new(nil, inner)
          i = j
        end
      end

      @menu_content = res.map(&:menu_output).join
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
      endpoints   = sections.reject { |s| s.is_a?(Scope) || s.name == 'desc' || s.name == 'object' }
      signatures  = endpoints.each_with_object("") do |e, res|
        res << %(<div class="resource-sig">#{e.signature}</div>)
      end
      scopes = sections.select { |s| s.is_a?(Scope) }.map!(&:generate_example).join("\n")

      @example = <<-HTML
      <div class="section-response">
        <div class="response-topbar">ENDPOINTS</div>
        <div class="section-endpoints">#{signatures}</div>
      </div>
      #{scopes}
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
        if endpoint.is_a?(Hash)
          n, values = endpoint.each_pair.first
          next unless n.start_with?('scope|')
          dir_name = n.slice(6..-1)

          scope_name = values['title'] || dir_name
          scoped_endpoints = values['endpoints']

          subsections = scoped_endpoints.each_with_object([]) do |e, r|
            filename = paths.dig(dir_name, e)
            next unless filename
            content  = File.read(filename)
            r << Section.new(e, content, resource: name)
          end

          res << Scope.new(scope_name, subsections)
          next res
        end

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

      inner = sections.flat_map(&:output).join("\n")
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

  class Group
    attr_reader :name, :resources

    def initialize(name, resources)
      @name       = name
      @resources  = resources
    end

    def output
      resources.map(&:output)
    end

    def menu_output
      title = "<h5 class=\"nav-group-title\">#{name}</h5>" if name && name.length > 0

      <<-HTML
        <div class="sidebar-nav-group">
          #{title}
          <ul>#{resources.map(&:menu_output).join}</ul>
        </div>
      HTML
    end
  end

  class Scope
    attr_reader :name, :sections

    def initialize(name, sections)
      @name       = name
      @sections   = sections
    end

    def output
      sections.map(&:output)
    end

    def menu_output
      <<-HTML
        <li>
          <div class="scope-title">#{name}</div>
          <ul class="scoped">#{sections.map(&:menu_output).join}</ul>
        </li>
      HTML
    end

    def generate_example
      signatures  = sections.each_with_object("") do |s, res|
        res << %(<div class="resource-sig">#{s.signature}</div>)
      end

      <<-HTML
      <div class="section-response">
        <div class="response-topbar">#{name} ENDPOINTS</div>
        <div class="section-endpoints">#{signatures}</div>
      </div>
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
      @tree = build_content_tree
      nodes = build_nodes(config['resources'])

      out = File.new("#{Dir.tmpdir}/rtfdoc_output.html", 'w')
      out.write(Template.new(nodes, config).output)
      out.close
    end

    private

    def build_nodes(ary, allow_groups: true)
      ary.map do |rs|
        if rs.is_a?(Hash)
          name, values = rs.each_pair.first

          if name.start_with?('group|')
            raise 'Nested groups are not yet supported' if !allow_groups

            group_name = values.key?('title') ? values['title'] : name.slice(6..-1)
            Group.new(group_name, build_nodes(values['resources'], allow_groups: false))
          else
            paths = @tree[name]
            Resource.build(name, paths, endpoints: values)
          end
        else
          paths = @tree[rs]
          paths.is_a?(Hash) ? Resource.build(rs, paths) : Section.new(rs, File.read(paths))
        end
      end
    end

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
