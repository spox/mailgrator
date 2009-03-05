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
            else
                start_sync
            end
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
            @sync.dest_account = @dest_acct
            @sync.src_account = @src_acct
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
    end

end