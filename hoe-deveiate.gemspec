# -*- encoding: utf-8 -*-
# stub: hoe-deveiate 0.4.0.pre20140405143322 ruby lib

Gem::Specification.new do |s|
  s.name = "hoe-deveiate"
  s.version = "0.4.0.pre20140405143322"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger"]
  s.cert_chain = ["/Users/ged/.gem/ged-public_gem_cert.pem"]
  s.date = "2014-04-05"
  s.description = "A collection of Rake tasks and utility functions I use to maintain my Open\nSource projects. It's really only useful if you want to help maintain one of\nthem."
  s.email = ["ged@FaerieMUD.org"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = ["ChangeLog", "History.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "lib/hoe/deveiate.rb"]
  s.homepage = "http://deveiate.org/hoe-deveiate"
  s.licenses = ["BSD"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.2.2"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "A collection of Rake tasks and utility functions I use to maintain my Open Source projects"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hoe>, ["~> 3.11"])
      s.add_runtime_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_runtime_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_runtime_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_runtime_dependency(%q<mail>, ["~> 2.5"])
      s.add_runtime_dependency(%q<rspec>, ["~> 2.14"])
      s.add_runtime_dependency(%q<rdoc>, ["~> 4.1"])
    else
      s.add_dependency(%q<hoe>, ["~> 3.11"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<mail>, ["~> 2.5"])
      s.add_dependency(%q<rspec>, ["~> 2.14"])
      s.add_dependency(%q<rdoc>, ["~> 4.1"])
    end
  else
    s.add_dependency(%q<hoe>, ["~> 3.11"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<mail>, ["~> 2.5"])
    s.add_dependency(%q<rspec>, ["~> 2.14"])
    s.add_dependency(%q<rdoc>, ["~> 4.1"])
  end
end
