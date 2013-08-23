# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "cantor"
  s.version = "0.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delon", "Newman"]
  s.date = "2013-08-23"
  s.description = "Reportable, exportable data sets and relational logic"
  s.email = "drnewman@phrei.org"
  s.extra_rdoc_files = [
    "README",
    "TODO"
  ]
  s.files = [
    "README",
    "Rakefile",
    "TODO",
    "VERSION",
    "lib/cantor.rb",
    "lib/cantor/lazy.rb",
    "lib/cantor/report.rb",
    "lib/cantor/set.rb",
    "test/common.rb",
    "test/members.rb",
    "test/pdf.rb",
    "test/set.rb"
  ]
  s.homepage = "http://github.com/delonnewman/cantor"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.0"
  s.summary = "Reportable, exportable data sets and relational logic"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_runtime_dependency(%q<prawn>, [">= 0"])
    else
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<prawn>, [">= 0"])
    end
  else
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<prawn>, [">= 0"])
  end
end
