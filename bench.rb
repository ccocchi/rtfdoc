require 'benchmark/ips'
require 'erubi'

buf = Erubi::Engine.new('
<div class="list-item-label">
  <div class="list-item-name"><%= @name %></div>
  <div class="list-item-type"><%= @type %></div>
</div>')

@name = 'foo'
@type = 'string'

def method(name, type)
  '<div class="list-item-label"><div class="list-item-name">' << name << '</div><div class="list-item-type">' << type << '</div></div>'
end

foo = Class.new {
  def initialize(name, type)
    @name, @type = name, type
  end

  class_eval("define_method(:_template) { #{buf.src} }")
}

puts foo.new(@name, @type)._template

Benchmark.ips do |x|
  x.report('eval') { eval(buf.src) }
  x.report('meth') { foo.new(@name, @type)._template }

  x.compare!
end
