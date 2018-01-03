# -*- encoding: utf-8 -*-
# stub: hoe-deveiate 0.9.0.pre20171222115422 ruby lib

Gem::Specification.new do |s|
  s.name = "hoe-deveiate".freeze
  s.version = "0.9.0.pre20171222115422"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2017-12-22"
  s.description = "A collection of Rake tasks and utility functions I use to maintain my Open\nSource projects. It's really only useful if you want to help maintain one of\nthem.".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "History.rdoc".freeze, "README.rdoc".freeze]
  s.files = ["ChangeLog".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "lib/hoe/deveiate.rb".freeze]
  s.homepage = "http://deveiate.org/hoe-deveiate".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "2.6.14".freeze
  s.signing_key = "/Volumes/Keys and Things/ged-private_gem_key.pem".freeze
  s.summary = "A collection of Rake tasks and utility functions I use to maintain my Open Source projects".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hoe>.freeze, ["~> 3.16"])
      s.add_runtime_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_runtime_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_runtime_dependency(%q<mail>.freeze, ["~> 2.6"])
      s.add_runtime_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_runtime_dependency(%q<rdoc>.freeze, ["~> 6.0"])
    else
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<mail>.freeze, ["~> 2.6"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 6.0"])
    end
  else
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<mail>.freeze, ["~> 2.6"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.0"])
  end
end
