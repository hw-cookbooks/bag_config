# This is a proxy object used within recipes
# to allow bag based attribute overrides
class NodeOverride
  # Recipe this proxy instance is associated to
  attr_accessor :context

  # context:: Chef::Recipe, Chef::Resource, Chef::Provider or Erubis::Context
  # Create a new NodeOverride proxy
  def initialize(context)
    @context = context
  end

  def node
    context && context.original_node
  end

  # key:: base key accessing attributes
  # Returns data bag name if custom data bag is in use
  def data_bag_name(key)
    name = key
    if(node[:bag_config][key] && node[:bag_config][key][:bag])
      name = node[:bag_config][key][:bag]
    end
    name
  end

  # key:: base key accessing attributes
  # Returns data bag item name if custom data bag item name is in use
  def data_bag_item_name(key)
    name = "config_#{node.name.gsub('.', '_')}"
    if(node[:bag_config][key] && node[:bag_config][key][:item])
      name = node[:bag_config][key][:item]
    end
    name
  end

  # key:: base key accessing attributes
  # Returns if the data bag item is encrypted
  def encrypted_data_bag_item?(key)
    encrypted = false
    if(node[:bag_config][key])
      encrypted = !!node[:bag_config][key][:encrypted]
    end
    encrypted
  end

  # key:: base key accessing attributes
  # Returns data bag item secret if applicable
  def data_bag_item_secret(key)
    secret = nil
    if(node[:bag_config][key] && node[:bag_config][key][:secret])
      secret = node[:bag_config][key][:secret]
      if(File.exists?(secret))
        secret = Chef::EncryptedDataBagItem.load_secret(secret)
      end
    end
    secret
  end

  # key:: base key accessing attributes
  # Returns proper key to use for index based
  def data_bag_item(key)
    key = key.to_sym if key.respond_to?(:to_sym)
    @@cached_items ||= {}
    begin
      if(@@cached_items[key].nil?)
        if(encrypted_data_bag_item?(key))
          @@cached_items[key] = Chef::EncryptedDataBagItem.load(
            data_bag_name(key),
            data_bag_item_name(key),
            data_bag_item_secret(key)
          ).to_hash
        else
          @@cached_items[key] = Chef::DataBagItem.load(
            data_bag_name(key),
            data_bag_item_name(key)
          )
        end
      end
    rescue => e
      Chef::Log.debug("Failed to retrieve configuration data bag item (#{key}): #{e}")
      @@cached_items[key] = false
    end
    @@cached_items[key]
  end

  # key:: Attribute key
  # Checks if data bag entry lookup is allowed based on white
  # and blacklist values
  def lookup_allowed?(key)
    allowed = true
    unless(node[:bag_config][:bag_whitelist].empty?)
      allowed = node[:bag_config][:bag_whitelist].map(&:to_s).include?(key.to_s)
    end
    if(allowed && !node[:bag_config][:bag_blacklist].empty?)
      allowed = !node[:bag_config][:bag_blacklist].map(&:to_s).include?(key.to_s)
    end
    Chef::Log.debug("BagConfig not allowed to fetch config for base key: #{key}") unless allowed
    allowed
  end

  # key:: Attribute key
  # Returns attribute with bag overrides if applicable
  def [](key)
    key = key.to_sym if key.respond_to?(:to_sym)
    if(!key.to_s.empty?)
      val = data_bag_item(key) if lookup_allowed?(key)
      if(val)
        val.delete('id')
        atr = Chef::Node::Attribute.new(
          node.normal_attrs,
          node.default_attrs,
          Chef::Mixin::DeepMerge.merge(
            node.override_attrs,
            Mash.new(key => val.to_hash)
          ),
          node.automatic_attrs
        )
        res = atr[key]
      end
      res || node[key]
    end
  end

  # Provides proper proxy to Chef::Node instance
  def method_missing(symbol, *args)
    if(node.respond_to?(symbol))
      node.send(symbol, *args)
    else
      if args.empty?
          self[symbol]
      else
        node.send(symbol, *args)
      end
    end
  end
end

module BagConfig

  # Override for #node method
  def override_node
    if(@_node_override.nil? || @_node_override.node != original_node)
      @_node_override = NodeOverride.new(self)
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
Chef::Resource.send(:include, BagConfig)
Chef::Provider.send(:include, BagConfig)
::Erubis::Context.send(:include, BagConfig)
