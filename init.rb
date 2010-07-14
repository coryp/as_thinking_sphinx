ActiveScaffold rescue
  raise "ActiveScaffoldSchema depends on ActiveScaffold. Enable the plugin first"
begin
  gem "thinking-sphinx"
rescue Gem::LoadError
  puts "Thinking Sphinx gem not installed"
end
 
ActiveScaffold::Config::Search.class_eval do
  def engine
    unless @engine
      @engine
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
		if active_scaffold_config.search.engine == "thinking_sphinx"
			@query = params[:search].to_s.strip rescue ''
      unless @query.empty?
				puts "############## Doing Thinking Sphinx Search"	
				begin
				  sphinx_results = self.controller_name.classify.constantize.search(@query, :select => :id, :limit => 50)
				rescue NoMethodError
					puts "############## Thinking Sphinx not configured on model, falling back"
					do_original_search
					return
				end
				search_conditions = { :id => sphinx_results.collect { |x| x.id } }
				self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, search_conditions)
				do_original_search
			end		
		else
			puts "############## Doing Original Search"	
			do_original_search
		end
		
		
	end
end

