require 'optparse'

@actions_path = File.join(File.dirname(__FILE__), 'actions')

if not ARGV[0].nil? and not ARGV[0].empty?
  action_name = ARGV[0]
  action = File.join(@actions_path, action_name)
  begin
    require action
  rescue
    puts "unknown action: #{action_name}"
  end
end

# if we got here, there was either no action, or the action was invalid
OptionParser.new do |opts|
  opts.banner = "Archetype command line actions\n\n"
  opts.define_head "Usage: archetype <action> [options]"
  opts.separator ""
  opts.separator "Available Actions:"
  Dir.glob("#{@actions_path}/*.rb") do |action|
    @description = true
    load action
    opts.separator "  * #{File.basename(action, '.rb')}\t- #{@description}"
  end
  puts opts
end.parse!
