#!/usr/bin/env rake

require 'hoe'

Hoe.add_include_dirs 'lib'

Hoe.plugin :mercurial
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'hoe-deveiate' do
	self.readme_file = 'README.md'
	self.history_file = 'History.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency( 'hoe-highline', '~> 0.0' )
	self.dependency( 'hoe-mercurial', '~> 1.0' )
	self.dependency( 'tmail', '~> 1.2' )

	self.spec_extras[:licenses] = ["BSD"]
	self.require_ruby_version( '>=1.8.7' )
	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"

	self.email_to.replace([ 'ged@FaerieMUD.org' ]) if self.respond_to?( :email_to )
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

