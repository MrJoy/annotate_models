# Smoke test to assure basic functionality works on a variety of Rails versions.
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'files'
require 'wrong'
require 'rake'
include Files
include Wrong::D

RVM_BIN = `which rvm`.chomp
USING_RVM = (RVM_BIN != '')

CURRENT_RUBY = `rvm-prompt i v p 2>/dev/null`.chomp
ENV['rvm_pretty_print_flag'] = '0'
ENV['BUNDLE_GEMFILE'] = './Gemfile'

describe "annotate inside Rails, using #{CURRENT_RUBY}" do
  here = File.expand_path('..', __FILE__)
  Annotate::Integration::SCENARIOS.each do |test_rig, base_dir, test_name|
    it "works under #{test_name}" do
      if(!USING_RVM)
        pending "Must have RVM installed."
        next
      end

      # Don't proceed if the working copy is dirty!
      Annotate::Integration.is_clean?(test_rig).should == true

      Bundler.with_clean_env do
        dir base_dir do
          temp_dir = Dir.pwd
          File.basename(temp_dir).should == base_dir

          # Delete cruft from hands-on debugging...
          Annotate::Integration.nuke_cruft(test_rig)

          # Copy everything to our test directory...
          exclusions = ["#{test_rig}/.", "#{test_rig}/.."]
          FileUtils.cp_r(FileList["#{test_rig}/*", "#{test_rig}/.*"] - exclusions, temp_dir)

          Annotate::Integration.compile_templates(base_dir, temp_dir, false)

          # By default, rvm_ruby_string isn't inherited over properly, so let's
          # make sure it's there so our .rvmrc will work.
          ENV['rvm_ruby_string']=CURRENT_RUBY

          require "#{base_dir}" # Will get "#{base_dir}.rb"...
          klass = "Annotate::Validations::#{base_dir.gsub('.', '_').classify}".constantize

          Dir.chdir(temp_dir) do
            output = `
              (
                source .rvmrc &&
                #{klass.test_commands}
              ) 2>&1`.chomp
            klass.verify_output(output)
            klass.verify_files(test_rig)
          end
        end
      end
    end
  end
end
