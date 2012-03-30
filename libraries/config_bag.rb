# This is a proxy object used within recipes
# to allow bag based attribute overrides
class NodeOverride
  # Access to actual node instance
  attr_accessor :node
  # Recipe this proxy instance is associated to
  attr_accessor :recipe

  # node:: Chef::Node
  # recipe:: Chef::Recipe
  # Create a new NodeOverride proxy
  def initialize(node, recipe)
    @node = node
    @recipe = recipe
  end

  # key:: Attribute key
  # Returns attribute with bag overrides if applicable
  def [](key)
    if(key.to_s == @recipe.node_key.to_s)
      val = @recipe.retrieve_data_bag
      if(val)
        val.delete('id')
        atr = Chef::Node::Attribute.new(
          node.normal_attrs,
          node.default_attrs,
          Chef::Mixin::DeepMerge.merge(
            node.override_attrs,
            Mash.new(@recipe.node_key => val)
          ),
          node.automatic_attrs
        )
        res = atr[key]
      end
    end
    res || node[key]
  end

  # Provides proper proxy to Chef::Node instance
  def method_missing(symbol, *args)
    if(@node.respond_to?(symbol))
      @node.send(symbol, *args)
    else
      self[args.first]
    end
  end

end

module BagConfig

  # key_override:: Key used against node to access attributes
  # Overrides key used to access node attributes. By default
  # the cookbook name is used
  def override_node_key(key_override)
    @_cookbook_name_override = key_override
  end

  # Returns key to be used when accessing attributes via #node
  def node_key
    @node_key || @_cookbook_name_override || @cookbook_name || cookbook_name
  end

  # name_override:: Data bag name
  # Overrides the data bag name configuration entries are stored.
  # By default the name of the data bag is the same as #node_key
  # which defaults to the name of the cookbook
  def override_data_bag(name_override)
    @_data_bag_override = name_override
  end

  # Return data bag override if available
  def attribute_databag_override
    if(has_node_attributes?)
      original_node[node_key][:config_data_bag_override]
    end
  end

  # Returns the name of the data bag containing configuration entries
  def data_bag
    @_data_bag_override || attribute_databag_override || node_key
  end

  # args:: attribute names
  # Returns hash of requested attributes
  def bag_or_node_args(*args)
    Hash[*args.flatten.map{|k| [k.to_sym,bag_or_node(k.to_sym)]}.flatten]
  end

  # key:: attribute key
  # bag:: optional data bag
  # Returns value from data bag for provided key and falls back to 
  # node attributes if no value is found within data bag
  def bag_or_node(key, bag=nil)
    bag ||= retrieve_data_bag
    val = bag[key.to_s] if bag
    val || @node[key]
  end

  # Returns configuration data bag
  def retrieve_data_bag
    unless(@_cached_bag)
      begin
        if(data_bag_encrypted?)
          @_cached_bag = Chef::EncryptedDataBagItem.load(
            data_bag, data_bag_name, data_bag_secret
          )
        else
          @_cached_bag = Chef::DataBagItem.load(data_bag, data_bag_name)
        end
      rescue => e
        Chef::Log.debug("No configuration bag found: #{e}")
      end
    end
    @_cached_bag
  end

  # Returns data bag entry name based on node attributes or
  # defaults to using node name prefixed with 'config_'
  def data_bag_name
    if(has_node_attributes?)
      if(original_node[node_key][:config_bag])
        if(original_node[node_key][:config_bag].respond_to?(:has_key?))
          name = original_node[node_key][:config_bag][:name].to_s
        else
          name = original_node[node_key][:config_bag].to_s
        end
      end
    end
    name.to_s.empty? ? "config_#{node.name.gsub('.', '_')}" : name
  end

  # Checks node attributes to determine if data bag is encrypted
  def data_bag_encrypted?
    if(has_node_attributes?)
      if(original_node[node_key][:config_bag].respond_to?(:has_key?))
        !!original_node[node_key][:config_bag][:encrypted]
      else
        false
      end
    end
  end

  # Returns data bag secret if data bag is encrypted
  def data_bag_secret
    if(data_bag_encrypted?)
      secret = original_node[node_key][:config_bag][:secret]
      if(File.exists?(secret))
        Chef::EncryptedDataBagItem.load_secret(secret)
      else
        secret
      end
    end
  end

  # Returns if the node has attributes for the given #node_key
  def has_node_attributes?
    !original_node[node_key].nil?
  end

  # Override for #node method
  def override_node
    if(@_node_override.nil? || @_node_override.node != original_node)
      @_node_override = NodeOverride.new(original_node, self)
    end
    @_node_override
  end

  # Aliases around the #node based methods
  def self.included(base) # :nordoc:
    base.class_eval do
      alias_method :original_node, :node
      alias_method :node, :override_node
    end
  end

end

# Hook everything in
Chef::Recipe.send(:include, BagConfig)
::Erubis::Context.send(:include, BagConfig)

# Template wrap only needs to be applied to recipe instances
Chef::Recipe.class_eval do
  # Wrap template resource so we can add the proper node key
  def template(*args, &block)
    resource = method_missing(*args.unshift(:template), &block)
    ## This is the important part
    resource.variables[:node_key] = self.node_key
    resource
  end
end
