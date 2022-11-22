entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
pack_path = Rails.root.join(entrypoint, "application.js")
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

if !pack_path.exist?
  say "❌ #{friendly_pack_path} is missing. You need a valid application pack file to proceed.", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

# verify that all critical dependencies are up to date; if not, queue for later
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
package_json = Rails.root.join("package.json")
lines = File.readlines(package_json)

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus["']: ["']\^3.1.0["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@hotwired/stimulus@^3.1\n", verbose: false)
  say "✅ Enqueued @hotwired/stimulus@^3.1 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus-webpack-helpers["']: ["']\^1.0.1["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@hotwired/stimulus-webpack-helpers@^1.0.1\n", verbose: false)
  say "✅ Enqueued @hotwired/stimulus-webpack-helpers@^1.0.1 to be added to dependencies"
end

controllers_path = Rails.root.join(entrypoint, "controllers")
template_src = File.read("tmp/stimulus_reflex_installer/template_src")
controller_templates_path = File.expand_path(template_src + "/app/javascript/controllers", File.join(File.dirname(__FILE__)))
application_controller_src = controller_templates_path + "/application_controller.js.tt"
application_controller_path = controllers_path.join("application_controller.js")
application_src = controller_templates_path + "/application.js.tt"
application_path = controllers_path.join("application.js")
index_src = controller_templates_path + "/index.js.shakapacker.tt"
index_path = controllers_path.join("index.js")

# create entrypoint/controllers, as well as the index, application and application_controller
empty_directory controllers_path unless controllers_path.exist?

copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?
copy_file(application_src, application_path) unless application_path.exist?
copy_file(index_src, index_path) unless index_path.exist?

pack = File.read(pack_path)
controllers_pattern = /import ['"]controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if pack.match?(controllers_pattern)
  if pack.match?(controllers_commented_pattern)

    options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
    options = YAML.safe_load(File.read(options_path))

    proceed = if options.key? "uncomment"
      options["uncomment"]
    else
      !no?("Do you want to import your Stimulus controllers in application.js? (Y/n)")
    end

    if proceed
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ controllers_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \"controllers\"\n"
      File.write(pack_path, lines.join)
      say "✅ Stimulus controllers imported in #{friendly_pack_path}"
    else
      say "❔ your Stimulus controllers are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ Stimulus controllers imported in #{friendly_pack_path}"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, "import \"controllers\"\n"
  File.write(pack_path, lines.join)
  say "✅ Stimulus controllers imported in #{friendly_pack_path}"
end

create_file "tmp/stimulus_reflex_installer/shakapacker", verbose: false
