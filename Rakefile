# Jeweler
begin
	require 'rubygems'
  require 'jeweler'
  Jeweler::Tasks.new do |spec|
    spec.name        = "cantor"
    spec.summary     = "Reportable, exportable data sets and relational logic"
    spec.description = spec.summary
    spec.email       = "drnewman@phrei.org"
    spec.homepage    = "http://github.com/delonnewman/church"
    spec.authors     = %w{Delon Newman}

    # Dependecies
    spec.add_development_dependency('jeweler')

		spec.add_dependency('prawn')
		spec.add_dependency('fastercsv')
  end
rescue LoadError
  puts "Jeweler not available.  Install it with: gem install jeweler"
end

desc "Push changes to git and deploy to system"
task :deploy do
	sh "git push"
	sh "sudo ggem cantor"
end
