require "test_helper"

class ExtendedBundler::HandlersTest < Minitest::Test
  def test_all_handlers_valid_yml_files
    each_handler do |file|
      assert_equal '.yml', File.extname(file), "#{file} should use the extension yml"
      begin
        YAML.load_file(file)
      rescue => e
        flunk "#{file} was not a valid yaml file: #{e}"
      end
    end
  end

  def test_all_handlers_valid_format
    each_handler do |file|
      yaml = YAML.load_file(file)
      assert_kind_of Array, yaml, "#{file} should be an array of hashes"

      yaml.each do |handler|
        assert_kind_of Hash, handler, "handler entries should be hashes in #{file}"

        # Versions should be the string all, or a hash
        assert_includes handler.keys, 'versions', "handler/versions should exist in #{file}"
        if handler['versions'].is_a?(String)
          assert_equal 'all', handler['versions'],
            "handler/versions should be the string all or a hash in #{file}"
        else
          assert_kind_of Hash, handler['versions'],
            "handler/versions should be the string all or a hash in #{file}"
        end

        # Matching should be an array of strings
        assert_includes handler.keys, 'matching',
          "handler/matching should exist in #{file}"
        assert_kind_of Array, handler['matching'],
            "handler/matching should be an array of strings in #{file}"
        handler['matching'].each do |m|
          assert_kind_of String, m,
            "handler/matching should be an array of strings in #{file}"
        end

        # Messages should be a hash
        assert_includes handler.keys, 'messages',
          "handler/message should exist in #{file}"
        assert_kind_of Hash, handler['messages'],
          "handler/messages should be a hash of messages keyed by lang in #{file}"
        assert_includes handler['messages'].keys, 'en',
          "handler/messages should always include an English message at minimum in #{file}"
      end
    end
  end

  def each_handler
    handler_path = File.expand_path('../../../lib/extended_bundler/handlers/*', __FILE__)
    Dir.glob(handler_path).each { |f| yield(f) }
  end
end
