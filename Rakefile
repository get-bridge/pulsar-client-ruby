require "rspec/core/rake_task"
require "rake/extensiontask"

# Rake 10 forwards FileUtils options positionally, but Ruby 3 expects
# keyword arguments for methods like mkdir_p.
if RUBY_VERSION >= "3.0"
  module Rake
    module FileUtilsExt
      def mkdir_p(*args, **kwargs, &block)
        super(*args, **kwargs, &block)
      end

      def chdir(*args, **kwargs, &block)
        super(*args, **kwargs, &block)
      end

      def cp(*args, **kwargs, &block)
        super(*args, **kwargs, &block)
      end

      def install(*args, **kwargs, &block)
        super(*args, **kwargs, &block)
      end
    end
  end
end

RSpec::Core::RakeTask.new(:spec)

task :default => [:compile, :spec]

Rake::ExtensionTask.new "bindings" do |ext|
  ext.lib_dir = "lib/pulsar"
end
