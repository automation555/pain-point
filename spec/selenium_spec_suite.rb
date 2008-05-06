dir = File.dirname(__FILE__)
ARGV.push('--require', "#{dir}/spec_helpers/indented_text_formatter", '--options', "#{dir}/spec.opts")

Dir["#{dir}/{selenium}/**/*_spec.rb"].each do |file|
  require file
end