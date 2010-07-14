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
end



ActiveScaffold::Actions::Search.class_eval do
	
	alias_method :do_original_search, :do_search
	
  protected  
	def do_search
		# Thinking Sphinx is configured, use it
		if active_scaffold_config.search.engine == "thinking_sphinx"
			@query = params[:search].to_s.strip rescue ''
      unless @query.empty?
				begin
					# Run the search, returning only the ids
				  sphinx_results = self.controller_name.classify.constantize.search(@query, :select => :id, :limit => 50)
				rescue NoMethodError
					# There is no search method on the model, probably no indexes configured
					# Fallback to default SQL search
					do_original_search
					return
				end
				
				# Create the conditions
				search_conditions = { :id => sphinx_results.collect { |x| x.id } }
				
				# Add the ids to the conditions of the current search
				self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, search_conditions)
				
				# Nil the search parameter so it isn't passed to the original search
				params[:search] = nil
				
				do_original_search
			end		
		else
			# Fallback to default SQL search
			do_original_search
		end
	end
end

