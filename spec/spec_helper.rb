if ENV['COVERAGE']
  require 'coveralls'
  require 'codeclimate-test-reporter'
  require 'simplecov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      Coveralls::SimpleCov::Formatter,
      SimpleCov::Formatter::HTMLFormatter,
      CodeClimate::TestReporter::Formatter
    ]
  )

  SimpleCov.start
end

require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'
require 'rspec'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/string/inflections'
require 'annotate'
require 'annotate/parser'
require 'annotate/helpers'
require 'annotate/constants'
require 'byebug'

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_when_matching :focus
end

# Vendored from `files` gem v0.4.0, to update for newer Ruby.
module Files
  def self.default_options(level = 2)
    { remove: true, name: called_from(level) }
  end

  def self.called_from(level = 1)
    line = caller[level]
    line.gsub!(/^.:/, '') # correct for leading Windows C:
    File.basename line.split(':').first, '.rb'
  end

  def self.create(options = default_options, &block)
    require 'tmpdir'
    require 'fileutils'

    name = options[:name]
    root = Dir.tmpdir

    # if the user specified a root directory (instead of default Dir.tmpdir)
    if options[:path]
      # then we will create their directory for them (test context-be friendly)
      root = options[:path]
      FileUtils.mkdir_p(root)
      # if they gave relative path, this forces absolute
      root = File.expand_path(root)
    end

    path = File.join(root, "#{name}_#{Time.now.to_i}_#{rand(1000)}")
    Files.new path, block, options
  end

  # mixin methods
  # TODO: block
  def files(options = ::Files.default_options)
    @files ||= ::Files.create(options)
  end

  def file(...)
    files.file(...)
  end

  def dir(...)
    files.dir(...)
  end

  # concrete class for creating files and dirs under a temporary directory
  class Files
    attr_reader :root

    def initialize(path, block, options)
      @root = path
      @dirs = []
      dir nil, &block
      at_exit { remove } if options[:remove]
    end

    # only 1 option supported: 'src'. if specified, is copied into 'name'
    def dir(name, options = {}, &block)
      path = if name.nil?
               current
             else
               File.join(current, name)
             end
      FileUtils.mkdir_p path
      @dirs << name if name

      if options[:src]
        # copy over remote dir to this one
        FileUtils.cp_r(options[:src], path)
      end

      Dir.chdir(path) do
        instance_eval(&block) if block
      end
      @dirs.pop
      path
    end

    def file(name, contents = "contents of #{name}")
      if name.is_a? File
        FileUtils.cp name.path, current
        # TODO: return path
      else
        path = File.join(current, name)
        if contents.is_a? File
          FileUtils.cp contents.path, path
        else
          file_path = File.open(path, 'w') do |f|
            f.write contents
          end
        end
        path
      end
    end

    def remove
      FileUtils.rm_rf(@root) if File.exist?(@root)
    end

    private

    def current
      File.join @root, *@dirs
    end
  end
end

def Files(options = ::Files.default_options, &block)
  files = ::Files.create options, &block
  files.root
end
