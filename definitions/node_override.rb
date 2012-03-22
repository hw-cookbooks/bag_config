puts 'FOUND THIS THING'
define :node do
  puts "RUNNING THIS GUY"
  unless(@_node_override)
    @_node_override = NodeOverride.new(run_context.node, self)
  end
  @_node_override
end
