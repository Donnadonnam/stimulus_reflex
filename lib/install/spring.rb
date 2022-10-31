gemfile = Rails.root.join("Gemfile")
spring_pattern = /^[^#]*gem ["']spring["']/

proceed = true
lines = File.readlines(gemfile)
if lines.index { |line| line =~ spring_pattern }
  options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
  options = YAML.safe_load(File.read(options_path))

  if options.key? "spring"
    proceed = options["spring"]
  else
    proceed = !no?("Would you like to disable the spring gem? \nIt's been removed from Rails 7, and is the frequent culprit behind countless mystery bugs. (Y/n)")
  end
end

if proceed
  spring_watcher_pattern = /^[^#]*gem ["']spring-watcher-listen["']/
  bin_rails_pattern = /^[^#]*load File.expand_path\("spring", __dir__\)/

  if (index = lines.index { |line| line =~ spring_pattern })
    say "💡 Can't kill spring process without killing install. Please run: pkill -f spring (or restart your terminal)"

    remove_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
    FileUtils.touch(remove_gem_list)
    append_file(remove_gem_list, "spring\n", verbose: false)
    say "✅ Removed spring from Gemfile"

    if Rails.root.join("bin/spring").exist?
      run "bin/spring binstub --remove --all"
      say "✅ Removed spring binstubs"
    end

    bin_rails = Rails.root.join("bin/rails")
    bin_rails_content = File.readlines(bin_rails)
    if (index = bin_rails_content.index { |line| line =~ bin_rails_pattern })
      bin_rails_content[index] = "# #{bin_rails_content[index]}"
      File.write(bin_rails, bin_rails_content.join)
      say "✅ Removed spring from bin/rails"
    end
  else
    say "✅ spring has been successfully 86'd"
  end

  if lines.index { |line| line =~ spring_watcher_pattern }
    remove_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
    FileUtils.touch(remove_gem_list)
    append_file(remove_gem_list, "spring-watcher-listen\n", verbose: false)
    say "✅ Removed spring-watcher-listen from Gemfile"
  end
end

create_file "tmp/stimulus_reflex_installer/spring", verbose: false
