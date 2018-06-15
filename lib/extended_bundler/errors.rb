require "extended_bundler/errors/version"
require "extended_bundler/errors/formatter"
require "extended_bundler/backports"

require "bundler"
require "fileutils"
require "yaml"

module ExtendedBundler
  module Errors
    class << self
      # Registers the plugin and adds all needed hooks
      # Will call troubleshoot via the `after-install` hook if the install does not succeed
      def register
        return if defined?(@registered) && @registered
        @registered = true

        Bundler::Plugin.add_hook('after-install') do |spec_install|
          troubleshoot(spec_install) if spec_install.state != :installed
        end
      end

      # Troubleshoots a failed installation
      # Will return if we have no handlers for this gem, otherwise finds a handler to match against
      # Each YAML file is assumed to have an array of hashes with 3 keys in each hash
      # - versions : either `all` or a hash with min/max indicating the versions of the gem this applies to
      # - matching : An array of strings that will be used (as a regex) to match against the error message
      # - message : A message to tell the user instead of the original stack trace
      #
      # This works by finding all potential "handlers" for a given gem and finding one that matches the version
      # and has an output (in matching) that matches the message. If it does match, it will replace the error message
      # and provide step by step instructions on how to proceed
      #
      # @param spec_install [Bundler::ParallelInstaller::SpecInstallation] a SpecInstallation object from Bundler
      def troubleshoot(spec_install)
        path = handler_path(spec_install.name)
        return nil unless File.exist?(path)
        yaml = YAML.load_file(path)
        yaml.each do |handler|
          next unless version_match?(spec_install.spec.version, handler['versions'])
          next unless handler['matching'].any? { |m| spec_install.error =~ Regexp.new(m) }
          spec_install.error = build_error(spec_install, handler)
        end
      end

      private

      def version_match?(spec_version, matching_versions)
        # Valid versions are either the string `all` or a hash with min/max
        return true if matching_versions == 'all'

        # Validate the matching versions are correct (Hash)
        unless matching_versions.is_a?(Hash)
          return ArgumentError, 'matching key must be "all" or a hash with min/max'
        end

        # If we don't specify a minimum, we can just start from 0
        min = Gem::Version.new(matching_versions.fetch('min', '0'))

        # If we don't specify a max, we just dont compare against a max
        if matching_versions['max']
          max = Gem::Version.new(matching_versions['max'])
          return spec_version >= min && spec_version <= max
        end
        spec_version > min
      end

      def build_error(spec_install, handler)
        body = message(handler)
        # If we can pull out the original logs, add those to the message
        if log = spec_install.error.match(/Results logged to (?<message>.*)/)
          body += "\n{{bold:Original Logs are available at:}}\n" + log[:message]
        end

        # Otherwise just format what we have
        title = "#{spec_install.name} (#{spec_install.spec.version.to_s}) could not be installed"
        lines = [ "{{bold:#{title}}}", ("━" * title.length), body.lines.map(&:chomp) ].flatten
        formatted_lines = lines.map { |l| "{{red:┃}} #{l}".strip }
        ExtendedBundler::Errors::Formatter.new(formatted_lines.join("\n")).format
      end

      def message(handler)
        # Grab the LANG environment variable
        # Assume it's in Posix compliant ISO 15897 format (which is approx lang_region.encoding).
        # Grab the lang out of that. If for some reason this isn't available, default back to
        # English on any issue.
        iso_15897_posix_lang = ENV.fetch('LANG', 'en').split('_').first
        handler['messages'][iso_15897_posix_lang] || handler['messages']['en']
      end

      def handler_path(gem_name)
        File.expand_path("../handlers/#{gem_name}.yml", __FILE__)
      end
    end
  end
end
