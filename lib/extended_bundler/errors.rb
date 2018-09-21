require "extended_bundler/errors/version"
require "extended_bundler/errors/formatter"
require "extended_bundler/backports"
require "extended_bundler/cache"

require "bundler"
require "fileutils"
require "yaml"

module ExtendedBundler
  module Errors
    NATIVE_EXTENSION_MSG = ExtendedBundler::Errors::Formatter.new(<<-EOF).format
#{'=' * 20}
We weren't able to handle this error, but we noticed it is an issue with {{bold:native extensions}}.
It is recommended to:

1. Find a string in the output that looks like it could be unique to this failure
2. Search Google to try and find a solution
3. Make an issue on {{underline:#{ExtendedBundler::Errors::HOMEPAGE}}}
   with the output and any solutions you found
    EOF

    class << self
      # Registers the plugin and adds all needed hooks
      # Will call troubleshoot via the `after-install` hook if the install does not succeed
      def register
        return if defined?(@registered) && @registered
        @registered = true

        Bundler::Plugin.add_hook('after-install') do |spec_install|
          troubleshoot(spec_install) if spec_install.state != :installed
        end

        Bundler::Plugin.add_hook('before-install-all') do |_d|
          # This hook also makes bundler load the plugin
          # Because the plugin is loaded before everything, our after-install hook is registered
          update_handlers
          puts "[ExtendedBundler] Done"
          puts "=" * 30
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

        troubleshooted = false
        yaml = YAML.load_file(path)
        yaml.each do |handler|
          next unless version_match?(spec_install.spec.version, handler['versions'])
          next unless handler['matching'].any? { |m| spec_install.error =~ Regexp.new(m) }
          spec_install.error = build_error(spec_install, handler)
          troubleshooted
        end

        if !troubleshooted && spec_install.error.include?('Failed to build gem native extension')
          spec_install.error = spec_install.error + "\n\n" + NATIVE_EXTENSION_MSG
        end
      end

      private

      def update_handlers
        puts "[ExtendedBundler] Updating Extended Bundler Errors Index"
        handlers = Cache.handlers_index
        return if handlers.nil?

        handlers_to_update = []
        handlers.select do |entry|
          file, mtime = entry.split(',')
          # Handlers are up to date if they exist and the mtime hasnt changed on master
          # Otherwise, we need to update them locally
          up_to_date = File.exist?(file) && File.mtime(file).utc >= Time.parse(mtime)
          handlers_to_update << file unless up_to_date
        end

        return if handlers_to_update.empty?
        handlers_to_update.each do |handler|
          puts "[ExtendedBundler] Updating #{File.basename(handler, '.yml')}"
          File.write(handler, Cache.fetch_file(handler))
        end
      rescue => e
        path = File.expand_path("../../cache/error_#{Time.now.to_i}", __dir__)
        File.write(path, e.backtrace.join("\n"))

        puts "[ExtendedBundler] There was an error updating the handlers. We will try again in a day."
        puts "[ExtendedBundler] In the mean time, it would be appreciated to get an issue report."
        puts "[ExtendedBundler] Error: #{e}"
        puts ""
        puts "[ExtendedBundler] Click here to open an issue: #{ExtendedBundler::Errors::HOMEPAGE}/issues/new?title=#{e}"
        puts "[ExtendedBundler] Please include the content of #{path}"
      end

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
