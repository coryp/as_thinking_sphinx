ActiveScaffold rescue
  raise "#### Depends on ActiveScaffold. Enable the plugin first ####"
begin
  gem "thinking-sphinx"
rescue Gem::LoadError
  raise "#### Thinking Sphinx gem not installed ####"
end
 


ActiveScaffold::Config::Search.class_eval do
	# Add the 'engine' configuration option
  def engine
    unless @engine
      @engine
      # Default to SQL
      self.engine = 'sql'
    end
    @engine
  end

  def engine=(val)
    @engine = val
  end
  
 	# Add the 'model_name' configuration option
  def model_name
    unless @model_name
      @model_name
      self.model_name = nil
    end
    @model_name
  end 

  def model_name=(val)  
    @model_name = val
  end  
end


ActiveScaffold::Actions::Search.class_eval do
	
	alias_method :do_original_search, :do_search
	
  protected  
	def do_search
		# Thinking Sphinx is configured, use it
		if active_scaffold_config.search.engine == "thinking_sphinx"
      # We need to parse the raw query_string here since the params hash has not yet been created.
      query = search_params.to_s.strip rescue ''
			
      unless query.empty?
				begin
					# Run the search, returning only the ids
					active_scaffold_config.search.model_name.nil? ? @model_name = self.controller_name : @model_name = active_scaffold_config.search.model_name
				
				  sphinx_results = @model_name.classify.constantize.search('*' + query + '*', :select => :id, :limit => 50)
				
        rescue NoMethodError
					# There is no search method on the model, probably no indexes configured
					# Fallback to default SQL search
					do_original_search
					return
				end
				
				# Create the conditions
        ids = sphinx_results.collect { |x| x.id }

        search_conditions = {}
				search_conditions = { :id => ids }
				
				# Add the ids to the conditions of the current search
        self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, search_conditions)
        
        # Set the filtered flag based upon conditions
        @filtered = !search_conditions.blank?

        active_scaffold_config.list.user.page = nil

			end		
		else
			# Fallback to default SQL search
			do_original_search
		end
	end
end

