# ExtendedBundler::Errors

Extended Bundler Errors is a `bundler` plugin that makes gem installation errors more actionable, educative, and all around easier to understand.

Previously when gems fail, `bundler` would simply tell you it failed and give you any output from the gem itself. This often includes C traces from native extensions.

These are hard to follow, particularly for people new to Ruby, because it requires you to understand the underlying system, programs in use (Imagemagick, SSL libraries, parsers, etc), and the output is simply verbose.

This gem instead will try to match the output of the gem to a series of handlers (see `lib/extended_bundler/handlers` for a list). Each handler is specific to a gem, an matches one of many potential output. Once matched, we replace the error with something that explains the known problem, how to fix it, and (if possible) include a link to the original output.

Here is an example:

Before when RMagick fails to install, you got a verbose log.

![Before this plugin, RMagick failures were cryptic and confusing](https://user-images.githubusercontent.com/3074765/40488035-c89a6678-5f33-11e8-89fc-f66c054d8765.png)

After when it fails to install you get a specific, actionable reason and step-by-step guide on how to handle it.

![After This Plugin, RMagick has better errors](https://user-images.githubusercontent.com/3074765/40489293-c8cf8e9a-5f36-11e8-88f5-fceed052aa24.png)

## Installation

While this is a gem, you need to install it as a plugin:

`bundler plugin install extended_bundler-errors`

OR

`bundler plugin install extended_bundler-errors --git=https://github.com/Shopify/extended_bundler-errors.git`

## Development

It is recommended to install from `git` and work directly in a `bundle install` run.

You can also...

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Adding special handling for a bad error message

Errors will happen so we want to make sure we can respond to them properly. Instead of finding an answer on StackOverflow or somewhere ese, let's make sure everyone in the future can get a better error message directly in their terminal during the install.

To do this, you should:

1. Create a file under [lib/extended_bundler/handlers](https://github.com/jules2689/extended_bundler-errors/tree/master/lib/extended_bundler/handlers) named "GEM_NAME.yml"
2. Start with this template:
```yaml
-
  versions: all
  matching:
   - "Matching Text"
  messages:
    en: |
      My Message
```
3. Customize the template.

#### Customizing the template

There are a few keys to keep in mind:

- `versions` can be the word `all` or a hash with `min` and/or `max` versions
  - This is the versions to which the handler applies
- `matching` is an array of strings (escapped regex is ok) that will be applied against the original bad error message
  - You should find a unique string(s) that identifies a specific error
- `messages` is a hash of messages that we might be able to give to a user
  - `en` is required and is the default/English response
  - Other language iso codes can be provided. Users will be given a response based on their `LANG` env var setting

Note, this is an array of "matchers". We will try each one iteratively against the `GEM_NAME` until the first one matches. So if you have multiple handlers for a single gem, just continue expanding the yaml file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/extended_bundler-errors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ExtendedBundler::Errors project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/extended_bundler-errors/blob/master/CODE_OF_CONDUCT.md).
