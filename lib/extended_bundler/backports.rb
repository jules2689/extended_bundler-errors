require 'bundler/version'

# In Bundler <= 1.17, we do not have the `after-install` hook, so monkey patch Bundler to include it
puts "VERSION " + Gem::Version.new(Bundler::VERSION).inspect
if Gem::Version.new(Bundler::VERSION) < Gem::Version.new('1.17')
  # We need to make sure ParallelInstaller is defined before we can patch it
  require 'bundler/installer/parallel_installer'

  module Bundler
    class ParallelInstaller
      private

      alias_method :old_do_install, :do_install
      def do_install(spec_install, worker_num)
        ret = old_do_install(spec_install, worker_num)
        Bundler::Plugin.hook('after-install', ret)
        ret
      end
    end
  end
end
