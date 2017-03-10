# -*- ruby -*-
#encoding: utf-8

require 'pp'

require 'hoe'
require 'mail'
require 'net/smtp'
require 'openssl'
require 'pathname'
require 'tempfile'

Hoe.plugin( :highline, :mercurial )


# A collection of Rake tasks and utility functions I use to maintain my
# Open Source projects.
module Hoe::Deveiate

	# Library version constant
	VERSION = '0.9.0'

	# Version-control revision constant
	REVISION = %q$Revision$

	# Regexp to match trailing whitespace
	TRAILING_WHITESPACE_RE = /[ \t]+$/

	# Emoji for style advisories
	SADFACE = "\u{1f622}"

	# The name of the RVM gemset
	RVM_GEMSET = Pathname( '.gems' )


	### Set up defaults
	def initialize_deveiate
		$hoespec = self
		abort "requires the hoe-mercurial plugin" unless Hoe.plugins.include?( :mercurial )

		minor_version = VERSION[ /^\d+\.\d+/ ]
		self.extra_dev_deps << ['hoe-deveiate', "~> #{minor_version}"] unless
			self.name == 'hoe-deveiate'

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

		@quality_check_whitelist = Rake::FileList.new

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

	# The Rake::FileList that contains files that shouldn't be considered when doing
	# quality checks
	attr_reader :quality_check_whitelist


	### Add tasks
	def define_deveiate_tasks
		self.define_quality_tasks
		self.define_sanitycheck_tasks
		self.define_packaging_tasks
		self.define_announce_tasks
	end


	### Set up tasks for various code-quality checks.
	def define_quality_tasks
		self.define_whitespace_checker_tasks

		# Quality-check before checking in
		task 'hg:precheckin' => :quality_check
		task 'git:precheckin' => :quality_check

		desc "Run several quality-checks on the code"
		task :quality_check => [ :check_whitespace ]
	end


	### Set up tasks that check for poor whitespace discipline
	def define_whitespace_checker_tasks

		desc "Check source code for inconsistent whitespace"
		task :check_whitespace => [
			:check_for_trailing_whitespace,
			:check_for_mixed_indentation,
		]

		desc "Check source code for trailing whitespace"
		task :check_for_trailing_whitespace do
			lines = find_matching_source_lines do |line, _|
				line =~ TRAILING_WHITESPACE_RE
			end

			unless lines.empty?
				desc = "Found some trailing whitespace"
				describe_lines_that_need_fixing( desc, lines, TRAILING_WHITESPACE_RE )
				fail
			end
		end

		desc "Check source code for mixed indentation"
		task :check_for_mixed_indentation do
			lines = find_matching_source_lines do |line, _|
				line =~ /(?<!#)([ ]\t)/
			end

			unless lines.empty?
				desc = "Found mixed indentation"
				describe_lines_that_need_fixing( desc, lines, /[ ]\t/ )
				fail
			end
		end

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

		namespace :deps do

			if RVM_GEMSET.exist?
				desc "Update the project's RVM gemset"
				task :gemset do
					deps = make_gemset_recommendations( $hoespec.spec )
					updates = deps.values.compact

					if !updates.empty?
						$stderr.puts "%d gems in the current gemset have newer matching versions:" %
							 [ updates.length ]
						deps.each do |old, newer|
							next unless newer
							$stderr.puts "  #{old} -> #{newer}"
						end

						if ask( "Update? " )
							update_rvm_gemset( deps )
							run 'rvm', 'gemset', 'import', RVM_GEMSET.to_s
						end
					end
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


	### Update the contents of .rvm.gems to include the latest gems.
	def update_rvm_gemset( deps )
		tmp = Tempfile.new( 'gemset' )
		deps.keys.each {|dep| deps[dep.name] = deps.delete(dep) }

		RVM_GEMSET.each_line do |line|
			if line =~ /^\s*(#|$)/
				tmp.print( line )
			else
				gem, version = line.split( /\s+/, 2 )

				if (( newer = deps.delete(gem) ))
					tmp.puts( gem + ' -v' + newer.to_s )
				else
					tmp.print( line )
				end
			end
		end

		deps.each do |gem, newer|
			next unless newer
			tmp.puts( gem + ' -v' + newer.to_s )
		end

		tmp.close

		FileUtils.cp( tmp.path, RVM_GEMSET, :verbose => true )
	end


	### Print out the list of dependency calls that should be included in the
	### Hoespec in the Rakefile.
	def print_hoespec_dependencies( deps )
		deps.each_key do |dep|
			$stderr.puts "self.dependency '%s', '%s'" % [ dep.name, dep.version.to_s ]
		end
	end


	### Return a Hash of Gem::Dependency objects, the keys of which are dependencies
	### in the current gemspec, and the values are which are either +nil+ if the
	### current gemset contains the latest version of the gem which matches the
	### dependency, or the newer version if there is a newer one.
	def make_gemset_recommendations( gemspec )
		recommendations = {}
		fetcher = Gem::SpecFetcher.fetcher

		gemspec.dependencies.each do |dep|
			newer_dep = nil

			if (( mspec = dep.matching_specs.last ))
				newer_dep = Gem::Dependency.new( dep.name, dep.requirement, "> #{mspec.version}" )
			else
				newer_dep = Gem::Dependency.new( dep.name, dep.requirement )
			end

			remotes, _ = fetcher.search_for_dependency( newer_dep )
			remotes.map! {|gem, _| gem.version }

			if remotes.empty?
				recommendations[ dep ] = nil
			else
				recommendations[ dep ] = remotes.last
			end
		end

		return recommendations
	end


	### Define tasks used to announce new releases
	def define_announce_tasks

		# Avoid broken Hoe 3.0 task
		Rake::Task[:announce].clear if Rake::Task.task_defined?( :announce )
		Rake::Task[:send_email].clear if Rake::Task.task_defined?( :send_email )

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

				ssl_context = OpenSSL::SSL::SSLContext.new
				smtp.enable_starttls( ssl_context )

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


	# Return tuples of the form:
	#
	#   [ <filename>, <line number>, <line> ]
	#
	# for every line in the Gemspec's source files for which the block
	# returns true.
	def find_matching_source_lines
		matches = []

		source_files = $hoespec.spec.files.grep( /\.(h|c|rb)$/ )
		source_files -= self.quality_check_whitelist

		source_files.each do |filename|
			previous_line = nil

			IO.foreach( filename ).with_index do |line, i|
				matches << [filename, i + 1, line] if yield( line, previous_line )
				previous_line = line
			end
		end

		return matches
	end


	### Output a listing of the specified lines with the given +description+, highlighting
	### the characters matched by the specified +re+.
	def describe_lines_that_need_fixing( description, lines, re )
		say "\n"
		say SADFACE + "  " + color( "Oh noes! " + description, :header )

		grouped_lines = group_line_matches( lines )

		grouped_lines.each do |filename, linegroups|
			linegroups.each do |group, lines|
				if group.min == group.max
					say color("%s:%d" % [ filename, group.min ], :bold)
				else
					say color("%s:%d-%d" % [ filename, group.min, group.max ], :bold)
				end

				lines.each_with_index do |line, i|
					say "%s: %s" % [
						color( group.to_a[i].to_s, :dark, :white ),
						highlight_problems( line, re )
					]
				end
				say "\n"
			end
		end
	end


	# Return a Hash, keyed by filename, whose values are tuples of Ranges
	# and lines extracted from the given [filename, linenumber, line] +tuples+.
	def group_line_matches( tuples )
		by_file = tuples.group_by {|tuple| tuple.first }

		return by_file.each_with_object({}) do |(filename, lines), hash|
			last_linenum = 0
			linegroups = lines.slice_before do |filename, linenum|
				gap = linenum > last_linenum + 1
				last_linenum = linenum
				gap
			end

			hash[ filename ] = linegroups.map do |group|
				rng = group.first[1] .. group.last[1]
				grouplines = group.transpose.last
				[ rng, grouplines ]
			end
		end
	end


	### Transform invisibles in the specified line into visible analogues.
	def highlight_problems( line, re )
		line \
			.gsub( re )    { color $&, :on_red } \
			.gsub( /\t+/ ) { color "\u{21e5}   " * $&.length, :dark, :white }
	end

end # module Hoe::Deveiate

