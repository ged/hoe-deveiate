#!/usr/bin/env ruby

require 'hoe'
require 'tmail'
require 'net/smtp'
require 'openssl'

Hoe.plugin( :highline, :mercurial )


# A collection of Rake tasks and utility functions I use to maintain my
# Open Source projects.
# 
# @author Michael Granger <ged@FaerieMUD.org>
# 
module Hoe::Deveiate

	# Library version constant
	VERSION = '0.0.7'

	# Version-control revision constant
	REVISION = %q$Revision$


	### Set up defaults
	def initialize_deveiate
		$hoespec = self
		abort "requires the hoe-mercurial plugin" unless Hoe.plugins.include?( :mercurial )

		@email_to ||= []
		@email_from = nil unless defined?( @email_from )
		self.hg_sign_tags = true
		self.check_history_on_release = true

	    with_config do |config, _|
			self.spec_extras[:signing_key] = config['signing_key_file'] or
				abort "no signing key ('signing_key_file') configured."
			@email_config = config['email']
			@email_to = Array( @email_config['to'] )
	    end

		$stderr.puts "Done initializing hoe-deveiate" if Rake.application.options.trace
	end


	# Where to send announcement emails
	attr_reader :email_to

	# Who to send announcement emails as
	attr_accessor :email_from


	### Add tasks
	def define_deveiate_tasks

		task 'hg:precheckin' => [:spec] if File.directory?( 'spec' )
		task 'hg:prep_release' => :check_manifest

		# Rebuild the ChangeLog immediately before release
		task :prerelease => 'ChangeLog'

		### Task: prerelease
		unless Rake::Task.task_defined?( :pre )
			desc "Append the package build number to package versions"
			task :pre do
				rev = get_numeric_rev()
				trace "Current rev is: %p" % [ rev ]
				$hoespec.spec.version.version << "pre#{rev}"
				Rake::Task[:gem].clear

				Gem::PackageTask.new( $hoespec.spec ) do |pkg|
					pkg.need_zip = true
					pkg.need_tar = true
				end
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

			@email_from = @email_config['from'] ||= "%s <%s>" % self.developer.first
			smtp_host = @email_config['host'] || ask( "Email host: " )
			smtp_port = @email_config['port'] || 'smtp'
			smtp_port = Socket.getservbyname( smtp_port.to_s )
			smtp_user = @email_config['user']

			message = generate_email( :full )
			say "<%= color 'About to send this email:', :subheader %>"
			say( message )

			if agree( "\n<%= color 'Okay to send it?', :warning %> " )
				require 'socket'
				require 'net/smtp'
				require 'etc'

				username = smtp_user || ask( "Email username: " ) do |q|
					q.default = Etc.getlogin  # default to the current user
				end
				password = ask( "Email password for #{username}: " ) do |q|
					q.echo = color( '*', :yellow ) # Hide the password
				end

				say "Creating SMTP connection to #{smtp_host}:#{smtp_port}"
				smtp = Net::SMTP.new( smtp_host, smtp_port )
				smtp.set_debug_output( $stdout )
				smtp.esmtp = true

				# Don't verify the server cert, as my server's cert is self-signed
				ssl_context = OpenSSL::SSL::SSLContext.new
				ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
				smtp.enable_ssl( ssl_context )

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

