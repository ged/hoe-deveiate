#!/usr/bin/env ruby

require 'tmail'
require 'net/smtp'

# This gem depends on the prompts and stuff from hoe-highline
Hoe.plugin :highline
Hoe.plugin :mercurial


# A collection of Rake tasks and utility functions I use to maintain my
# Open Source projects.
# 
# @author Michael Granger <ged@FaerieMUD.org>
# 
module Hoe::Deveiate

	# Library version constant
	VERSION = '0.0.1'

	# Version-control revision constant
	REVISION = %q$Revision$


	### Set up defaults
	def initialize_deveiate
		self.hg_sign_tags = true

		@email_to = nil

	    with_config do |config, _|
			self.spec_extras[:signing_key] = config['signing_key_file'] or
				abort "no signing key ('signing_key_file') configured."
			@email_conf = config['email']
	    end
	end


	attr_accessor :email_to


	### Add tasks
	def define_deveiate_tasks

		# Rebuild the ChangeLog immediately before release
		task :prerelease => 'ChangeLog'

		# Ensure the specs pass before checking in
		task 'hg:precheckin' => :spec

		### Task: prerelease
		desc "Append the package build number to package versions"
		task :pre do
			rev = get_numeric_rev()
			trace "Current rev is: %p" % [ rev ]
			hoespec.spec.version.version << "pre#{rev}"
			Rake::Task[:gem].clear

			Gem::PackageTask.new( hoespec.spec ) do |pkg|
				pkg.need_zip = true
				pkg.need_tar = true
			end
		end

		### Make the ChangeLog update if the repo has changed since it was last built
		file '.hg/branch'
		file 'ChangeLog' => '.hg/branch' do |task|
			$stderr.puts "Updating the changelog..."
			content = make_changelog()
			File.open( task.name, 'w', 0644 ) do |fh|
				fh.print( content )
			end
		end

		# Announcement tasks, mostly stolen from hoe-seattlerb

		task :announce => :send_email

		desc "Send a release announcement to: %p" % [ @email_to ]
		task :send_email do
			abort "no email config in your ~/.hoerc" unless defined?( @email_config )
			@email_from ||= "%s <%s>" % self.developer.first

			message = generate_email( :full )
			say "About to send this:"
			say( mail )

			if agree( "Okay to send it? " )
				require 'socket'
				require 'net/smtp'
				require 'etc'

				username = ask( "Email username: " ) do |q|
					q.default = Etc.getlogin  # default to the current user
				end
				password = ask( "Email password: " ) do |q|
					q.echo = '*'  # Hide the password
				end

				say "Creating SMTP connection to #{SMTP_HOST}:#{SMTP_PORT}"
				smtp = Net::SMTP.new( SMTP_HOST, SMTP_PORT )
				smtp.set_debug_output( $stderr )
				smtp.esmtp = true
				smtp.enable_starttls

				helo = Socket.gethostname
				smtp.start( helo, username, password, :plain ) do |smtp|
					smtp.send_message( message, self.email_from, *self.email_to )
				end
			else
				abort "Okay, aborting."
			end
		end

	end

end # module Hoe::Deveiate

