class NodeOverride
  attr_accessor :node
  attr_accessor :recipe

  def initialize(node, recipe)
    @node = node
    @recipe = recipe
  end

  def [](key)
    val = @recipe.bag_or_node(key)
    val
  end

  def method_missing(symbol, *args)
    if(@node.respond_to?(symbol))
      @node.send(symbol, *args)
    else
      self[args.first]
    end
  end

end

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

  def attribute_databag_override
    if(has_node_attributes?)
      _node[node_key][:config_data_bag_override]
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
    puts "KEY :#{node_key}"
    puts _node
    puts '*' * 10
    puts run_context.node
    puts '* ' * 100
    val || _node[node_key][key]
  end

  # Returns configuration data bag
  def retrieve_data_bag
    unless(@_cached_bag)
      if(data_bag_encrypted?)
        @_cached_bag = Chef::EncryptedDataBagItem.load(
          data_bag, data_bag_name, data_bag_secret
        )
      else
        begin
          @_cached_bag = search(data_bag, "id:#{data_bag_name}").first
          @_cached_bag = Mash.new(@_cached_bag.raw_data) if @_cached_bag
        rescue Net::HTTPServerException
          Chef::Log.info("Search for #{data_bag} data bag failed meaning no configuration entries available.")
        end
      end
    end
    @_cached_bag
  end

  # Returns data bag entry name based on node attributes or
  # defaults to using node name prefixed with 'config_'
  def data_bag_name
    if(has_node_attributes?)
      if(_node[node_key][:config_bag])
        if(_node[node_key][:config_bag].respond_to?(:has_key?))
          name = _node[node_key][:config_bag][:name].to_s
        else
          name = _node[node_key][:config_bag].to_s
        end
      end
    end
    name.to_s.empty? ? "config_#{node.name.gsub('.', '_')}" : name
  end

  # Checks node attributes to determine if data bag is encrypted
  def data_bag_encrypted?
    if(has_node_attributes?)
      if(_node[node_key][:config_bag].respond_to?(:has_key?))
        !!_node[node_key][:config_bag][:encrypted]
      else
        false
      end
    end
  end

  # Returns data bag secret if data bag is encrypted
  def data_bag_secret
    if(data_bag_encrypted?)
      secret = _node[node_key][:config_bag][:secret]
      if(File.exists?(secret))
        Chef::EncryptedDataBagItem.load_secret(secret)
      else
        secret
      end
    end
  end

  def has_node_attributes?
    !_node[node_key].nil?
  end

  def _node
    run_context.node
  end


  def self.included(base)
    base.class_eval do
      def _node
        @run_context.node
      end
      
      def node
        puts "RUNNING THIS GUY"
        #        return _node
        unless(@_node_override)
          @_node_override = NodeOverride.new(run_context.node, self)
        end
        @_node_override
      end
    end
  end

end

Chef::Recipe.send(:include, ConfigBag)
