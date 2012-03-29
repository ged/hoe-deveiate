#!/usr/bin/env rake

require 'hoe'

Hoe.add_include_dirs 'lib'

Hoe.plugin :mercurial
Hoe.plugin :signing

# Hoe.plugins.delete :publish
Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'hoe-deveiate' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'hoe-highline', '~> 0.0'
	self.dependency 'hoe-mercurial', '~> 1.4'
	self.dependency 'mail', '~> 2.4'
	self.dependency 'rspec', '~> 2.9'
	self.dependency 'rdoc', '~> 3.12'

	self.spec_extras[:licenses] = ["BSD"]
	self.require_ruby_version( '>=1.8.7' )
	# self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

task :test_email, [:address] do |task, args|
	args.with_defaults( :address => 'rubymage@gmail.com' )
	hoespec.email_to.replace([ args.address ])
	Rake::Task[:send_email].execute
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

