#!/usr/bin/env rake
#encoding: utf-8

$LOAD_PATH.unshift 'lib'

require 'hoe'
require 'hoe/deveiate'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :highline

# Hoe.plugins.delete :publish
Hoe.plugins.delete :rubyforge

GEMSPEC = 'hoe-deveiate.gemspec'

# The specification
hoespec = Hoe.spec 'hoe-deveiate' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'hoe', '~> 3.16'
	self.dependency 'hoe-highline', '~> 0.2'
	self.dependency 'hoe-mercurial', '~> 1.4'
	self.dependency 'mail', '~> 2.6'
	self.dependency 'rspec', '~> 3.5'
	self.dependency 'rdoc', '~> 5.0'

	self.license 'BSD-3-Clause'
	self.require_ruby_version( '>=2.2.0' )
	# self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

task :test_email, [:address] do |task, args|
	args.with_defaults( :address => 'rubymage@gmail.com' )
	hoespec.email_to.replace([ args.address ])
	Rake::Task[:send_email].execute
end

ENV['VERSION'] ||= $hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => ['deps:gemset', :check_history, :check_manifest]


# Generate a .gemspec file for integration with systems that read it
task :gemspec => GEMSPEC
file GEMSPEC => __FILE__ do |task|
	spec = hoespec.spec
	spec.files.delete( '.gemtest' )
	spec.version = "#{spec.version}.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	File.open( task.name, 'w' ) do |fh|
		fh.write( spec.to_ruby )
	end
end
task :default => :gemspec

