#!/usr/bin/env ruby

require 'hoe'
require 'mail'
require 'net/smtp'
require 'openssl'

Hoe.plugin( :highline, :mercurial )


# A collection of Rake tasks and utility functions I use to maintain my
# Open Source projects.
module Hoe::Deveiate

	# Library version constant
	VERSION = '0.1.1'

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
			@email_to = if @email_config
					Array( @email_config['to'] )
				else
					['nobody@nowhere']
				end
	    end

		$stderr.puts "Done initializing hoe-deveiate" if Rake.application.options.trace
	end


	### Generate an announcement email.
	def generate_mail
		$stderr.puts "Generating an announcement email."
		abort "no email config in your ~/.hoerc" unless defined?( @email_config )

	    changes = self.changes
	    subject = "#{self.name} #{self.version} Released"
	    title   = "#{self.name} version #{self.version} has been released!"
	    body    = "#{self.description}\n\nChanges:\n\n#{self.changes}"
	    urls    = self.urls.map do |url|
			case url
			when Array
				"* <#{url[1].strip}> (#{url[0]})"
			when String
				"* <#{url.strip}>"
			else
				"* %p" % [ url ]
			end
		end

		$stderr.puts "  returning a new Mail::Message."
		mail         = Mail.new
		mail.from    = @email_config['from'] || "%s <%s>" % self.developer.first
		mail.to      = @email_to.join(", ")
		mail.subject = "[ANN] #{subject}"
		mail.body    = [ title, urls.join($/), body ].join( $/ * 2 )

		return mail
	end


	# Where to send announcement emails
	attr_reader :email_to

	# Who to send announcement emails as
	attr_accessor :email_from


	### Add tasks
	def define_deveiate_tasks
		self.define_sanitycheck_tasks
		self.define_packaging_tasks
		self.define_announce_tasks
	end


	### Set up some sanity-checks as dependencies of higher-level tasks
	def define_sanitycheck_tasks

		task 'hg:precheckin' => [:spec] if File.directory?( 'spec' )
		task 'hg:prep_release' => [ :check_manifest, :check_history ]

		# Rebuild the ChangeLog immediately before release
		task :check_manifest => 'ChangeLog'
		task :prerelease => 'ChangeLog'

	end


	### Set up tasks for use in packaging.
	def define_packaging_tasks

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

	end

	### Define tasks used to announce new releases
	def define_announce_tasks

		# Avoid broken Hoe 3.0 task
		Rake::Task[:announce].clear if Rake::Task.key?( :announce )
		Rake::Task[:send_email].clear if Rake::Task.key?( :send_email )

		desc "Announce a new release"
		task :announce => :send_email

		desc "Send a release announcement to: %p" % [ @email_to ]
		task :send_email do
			mail = generate_mail()

			say "<%= color 'About to send this email:', :subheader %>"
			say( mail.to_s )

			smtp_host = @email_config['host'] || ask( "Email host: " )
			smtp_port = @email_config['port'] || 'smtp'
			smtp_port = Socket.getservbyname( smtp_port.to_s )
			smtp_user = @email_config['user']

			if agree( "\n<%= color 'Okay to send it?', :warning %> ")
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
					mail.delivery_method( :smtp_connection, :connection => smtp )
					mail.deliver
				end


			else
				abort "Okay, aborting."
			end
		end

	end

end # module Hoe::Deveiate

