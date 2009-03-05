['MailSync', 'MboxAccount', 'ImapAccount', 'Exceptions'].each{|f| require "mailgrator/#{f}"}
module MailGrator

    class MailGrator
        # src:: mail source information hash
        # dest:: mail destination information hash
        # interactive:: should this be interactive
        # Creates new MailGrator
        def initialize(src, dest, interactive)
            @src = src
            @dest = dest
            @prompt = interactive
            @dest_acct = nil
            @src_acct = nil
            @sync = nil
        end

        # starts the program
        def start
            if(@prompt)
                start_questions
            end
            start_sync
        end

        private

        def show_status
            until(@sync.progress == 1)
                puts "#{@sync.progress * 100}%"
                sleep(1)
            end
        end

        def start_questions
            raise "Not Implemented"
        end

        def start_sync
            @sync = MailSync.new
            setup_accounts
            t1 = Thread.new do
                @sync.dest_account = @dest_acct
                Logger.info("Destination acccount connected and ready")
            end
            t2 = Thread.new do
                @sync.src_account = @src_acct
                Logger.info("Source account connected and ready")
            end
            t1.join
            t2.join
            @sync.sync_mail
            show_status
        end

        def setup_accounts
            unless(@dest[:mbox].nil?)
                @dest_acct = MboxAccount.new(@dest[:mbox])
            else
                @dest_acct = ImapAccount.new(@dest[:host], @dest[:user], @dest[:pass], @dest[:port], @dest[:secure])
            end
            unless(@src[:mbox].nil?)
                @src_acct = MboxAccount.new(@src[:mbox])
            else
                @src_acct = ImapAccount.new(@src[:host], @src[:user], @src[:pass], @src[:port], @src[:secure])
            end
            if(@dest_acct.is_a?(MboxAccount))
                raise InvalidMigration.new(@src_acct.class, @dest_acct.class)
            end
        end

        def start_questions
            puts '*****************************'
            puts '* Mailgrator Email Migrator *'
            puts '*****************************'
            puts ''
            puts '### Mail Source Configuration ###'
            s_type = get_input('Mail store type: ', '(mbox|imap)', 'imap')
            if(s_type == 'imap')
                imap_config(@src)
            else
                @src[:mbox] = get_input('Path to mbox files: ', '.+', './')
            end
            puts ''
            puts '### Mail Destination Configuration (IMAP only) ###'
            imap_config(@dest)
        end

        def imap_config(store)
            store[:host] = get_input('Mail server address: ', '.+', nil)
            store[:port] = get_input('Mail server port: ', '\d+', 143)
            store[:user] = get_input('Mail username: ', '.+', nil)
            store[:pass] = get_input('Mail password: ', '.+', nil)
            store[:secure] = get_input('Use secure connection: ', '(yes|no)', 'no') == 'yes'
        end

        ## helpers lifted from mod_spox ##

        # pattern:: regex response must match
        # default:: default value if response is empty
        # echo:: echo user's input
        # Reads users input
        def read_input(pattern=nil, default=nil)
            response = $stdin.readline
            response.strip!
            set = !response.empty?
            unless(pattern.nil?)
                response = nil unless response =~ /^#{pattern}$/
            end
            if(default && (!set || response.nil?))
                response = default
            end
            return response
        end

        # output:: to send before user input
        # regex:: pattern user input must match (^ and $ not needed. applied automatically)
        # echo:: echo user's input
        # default:: default value if no value is entered
        def get_input(output, regex, default=nil)
            response = nil
            until(response) do
                print output
                print "[#{default}]: " unless default.nil?
                $stdout.flush
                response = read_input(regex, default)
            end
            return response
        end
    end

end