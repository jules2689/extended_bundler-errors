require "test_helper"
require 'bundler/plugin'

class ExtendedBundler::ErrorsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ExtendedBundler::Errors::VERSION
  end

  class BaseTest < Minitest::Test
    def setup
      super
      Bundler::Plugin.instance_variable_set(:@hooks_by_event, Hash.new {|h, k| h[k] = [] })
      ExtendedBundler::Errors.instance_variable_set(:@registered, false)

      Bundler::Plugin.index.stubs(:hook_plugins).returns(['plugin'])
      Bundler::Plugin.stubs(:load_plugin).with('plugin')
    end
  end

  class RegisterTest < BaseTest
    def test_adds_hook
      ExtendedBundler::Errors.register
      assert_equal 1, Bundler::Plugin.instance_variable_get(:@hooks_by_event)['after-install'].size
    end

    def test_does_not_add_multiple_hooks
      ExtendedBundler::Errors.register
      ExtendedBundler::Errors.register
      assert_equal 1, Bundler::Plugin.instance_variable_get(:@hooks_by_event)['after-install'].size
    end
  end

  class TroubleshootTest < BaseTest
    def test_nothing_is_called_for_succeeded_install
      ExtendedBundler::Errors.register
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(Gem::Specification.new)
      spec_install.state = :installed
      ExtendedBundler::Errors.expects(:troubleshoot).never
      Bundler::Plugin.hook('after-install', spec_install)
    end

    def test_called_for_failed_install
      ExtendedBundler::Errors.register
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(Gem::Specification.new)
      spec_install.state = :failed
      ExtendedBundler::Errors.expects(:troubleshoot).with(spec_install)
      Bundler::Plugin.hook('after-install', spec_install)
    end
  end

  class MatchingTest < BaseTest
    def test_matches_name_version_and_message
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec)
      spec_install.state = :failed
      spec_install.error = "testing stuff only"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal testing_stuff_message, spec_install.error
    end

    def test_matches_name_version_but_not_message
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec)
      spec_install.state = :failed
      spec_install.error = "No matching stuff here"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal "No matching stuff here", spec_install.error
    end

    def test_matches_name_version_but_is_native_extension_issue
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec)
      spec_install.state = :failed
      spec_install.error = "Failed to build gem native extension"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal "Failed to build gem native extension\n\n#{ExtendedBundler::Errors::NATIVE_EXTENSION_MSG}",
        spec_install.error
    end

    def test_matches_name_but_not_version_with_min_max
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec(version: '0.5'))
      spec_install.state = :failed
      spec_install.error = "No package 'MagickCore' found"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal "No package 'MagickCore' found", spec_install.error
    end

    def test_matches_name_but_not_version_with_min
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec(name: 'testing_stuff_2', version: '0.5'))
      spec_install.state = :failed
      spec_install.error = "No package 'MagickCore' found"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal "No package 'MagickCore' found", spec_install.error
    end

    def test_doesnt_matches_name
      spec_install = Bundler::ParallelInstaller::SpecInstallation.new(gem_spec(name: 'no_match_gem'))
      spec_install.state = :failed
      spec_install.error = "No package 'MagickCore' found"
      ExtendedBundler::Errors.troubleshoot(spec_install)
      assert_equal "No package 'MagickCore' found", spec_install.error
    end

    def gem_spec(name: 'testing_stuff', version: '1.5')
      spec = Gem::Specification.new
      spec.name = name
      spec.version = Gem::Version.new(version)
      spec
    end

    def testing_stuff_message
      <<~EOF.chomp
      \e[0;31m┃\e[0m \e[0;1mtesting_stuff (1.5) could not be installed\e[0m
      \e[0;31m┃\e[0m ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      \e[0;31m┃\e[0m This is a message
      EOF
    end
  end
end
