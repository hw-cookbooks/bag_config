module ConfigBag

  # key_override:: Key used against node to access attributes
  # Overrides key used to access node attributes. By default
  # the cookbook name is used
  def override_node_key(key_override)
    @_cookbook_name_override = key_override
  end

  # Returns key to be used when accessing attributes via #node
  def node_key
    @_cookbook_name_override || cookbook_name
  end

  # name_override:: Data bag name
  # Overrides the data bag name configuration entries are stored.
  # By default the name of the data bag is the same as #node_key
  # which defaults to the name of the cookbook
  def override_data_bag(name_override)
    @_data_bag_override = name_override
  end

  # Returns the name of the data bag containing configuration entries
  def data_bag
    @_data_bag_override || node[node_key][:config_data_bag_override] || node_key
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
    val || node[node_key][key]
  end

  # Returns configuration data bag
  def retrieve_data_bag
    unless(@_cached_bag)
      if(data_bag_encrypted?)
        @_cached_bag = Chef::EncryptedDataBagItem.load(
          data_bag, data_bag_name, data_bag_secret
        )
      else
        @_cached_bag = search(data_bag, "id:#{data_bag_name}").first
      end
    end
    @_cached_bag
  end

  # Returns data bag entry name based on node attributes or
  # defaults to using node name prefixed with 'config_'
  def data_bag_name
    if(node[node_key][:config_bag])
      if(node[node_key][:config_bag].respond_to?(:has_key?))
        name = node[node_key][:config_bag][:name].to_s
      else
        name = node[node_key][:config_bag].to_s
      end
    end
    name.to_s.empty? ? "config_#{node.name.gsub('.', '_')}" : name
  end

  # Checks node attributes to determine if data bag is encrypted
  def data_bag_encrypted?
    if(node[node_key][:config_bag].respond_to?(:has_key?))
      !!node[node_key][:config_bag][:encrypted]
    else
      false
    end
  end

  # Returns data bag secret if data bag is encrypted
  def data_bag_secret
    if(data_bag_encrypted?)
      secret = node[node_key][:config_bag][:secret]
      if(File.exists?(secret))
        Chef::EncryptedDataBagItem.load_secret(secret)
      else
        secret
      end
    end
  end
end

Chef::Recipe.send(:include, ConfigBag)
