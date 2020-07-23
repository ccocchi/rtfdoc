require 'benchmark/ips'
require 'erubi'
#
# buf = Erubi::Engine.new('
# <div class="list-item-label">
#   <div class="list-item-name"><%= @name %></div>
#   <div class="list-item-type"><%= @type %></div>
# </div>')
#
# @name = 'foo'
# @type = 'string'
#
# def method(name, type)
#   '<div class="list-item-label"><div class="list-item-name">' << name << '</div><div class="list-item-type">' << type << '</div></div>'
# end
#
# foo = Class.new {
#   def initialize(name, type)
#     @name, @type = name, type
#   end
#
#   class_eval("define_method(:_template) { #{buf.src} }")
# }
#
# puts foo.new(@name, @type)._template
#
# Benchmark.ips do |x|
#   x.report('eval') { eval(buf.src) }
#   x.report('meth') { foo.new(@name, @type)._template }
#
#   x.compare!
# end


# str = 'content/intro/example.md'
#
# def meth1(str)
#   str.split('/').last.split('.').first
# end
#
# def meth2(str)
#   str.split('/').last.slice(0..-4)
# end
#
# def meth3(str)
#   i = str.rindex('/')
#   str.slice(i + 1..-4)
# end
#
# def meth4(str)
#   /(?<name>\w+)\.md\Z/.match(str)[:name]
# end
#
# def meth5(str)
#   i = str.rindex('/')
#   str.slice(i + 1, str.length - i - 4)
# end
#
# puts meth5(str)
#
# Benchmark.ips do |x|
#   x.report('meth1') { meth1(str) }
#   x.report('meth2') { meth2(str) }
#   x.report('meth3') { meth3(str) }
#   x.report('meth4') { meth4(str) }
#   x.report('meth5') { meth5(str) }
#
#   x.compare!
# end

# str   = '/Users/ccocchi/code/rtfdoc/content'
# str2  = '/Users/ccocchi/code/rtfdoc/content/**/*.md'
#
# def explore(path)
#   res = []
#   inner(path, res)
#   res
# end
#
# def inner(path, res)
#   Dir.each_child(path).each do |child|
#     cpath = "#{path}/#{child}"
#     if File.directory?(cpath)
#       inner(cpath, res)
#     else
#       res << cpath
#     end
#   end
# end
#
# puts explore(str).inspect
# puts Dir.glob(str2).inspect
#
# Benchmark.ips do |x|
#   x.report('explore') { explore(str) }
#   x.report('glob')    { Dir.glob(str2) }
#
#   x.compare!
# end

# @base_path  = File.expand_path('../content', __FILE__)
# tree        = {}
# slicer      = (@base_path.length + 1)..-1
# ext_slicer  = -3..-1
#
# Dir.glob("#{@base_path}/**/*.md").each do |path|
#   str       = path.slice(slicer)
#   parts     = str.split('/')
#   filename  = parts.pop
#   filename.slice!(ext_slicer)
#
#   puts parts
#   leaf = parts.reduce(tree) { |part, h| dir = {}; h[part] = dir; dir }
#   puts "leaf=#{leaf}"
# end

# buf = Erubi::Engine.new("<tr><%= content %></tr>", freeze: true)
# puts buf.src
#
# exit

content = "something"

Benchmark.ips do |x|
  x.report('inter') { "<tr>#{content}</tr>" }
  x.report('<<') { _buf = String.new; _buf << '<tr>'.freeze << content << '</tr>'.freeze }
  x.compare!
end
