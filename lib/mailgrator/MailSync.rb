['MailAccount', 'Exceptions', 'Logger'].each{|f|require "mailgrator/#{f}"}

module MailGrator
    class MailSync
        # max_threads:: max number of threads to create
        # Creates new MailSync
        def initialize(pool)
            @pool = pool
            @src_account = nil
            @dest_account = nil
            @initial_size = 0
            @procs_queue = []
        end

        # account:: MailAccount
        # set the source mail account
        def src_account=(account)
            raise InvalidType.new(MailAccount, account.class) unless account.is_a?(MailAccount)
            @src_account = account
        end

        # account:: MailAccount
        # set the destination mail account
        def dest_account=(account)
            raise InvalidType.new(MailAccount, account.class) unless account.is_a?(MailAccount)
            @dest_account = account
        end

        # synchronize mail from source to destination account
        def sync_mail
            raise EmptyAccounts.new(@src_account, @dest_account) if @src_account.nil? || @dest_account.nil?
            missing_folders = @dest_account.mailbox_list.missing(@src_account.mailbox_list.list)
            @dest_account.mailbox_list.add_mailboxes(missing_folders)
            @src_account.mailbox_list.list.sort.each do |mailbox|
                @procs_queue << Proc.new do
                    begin
                        sync(mailbox)
                    rescue Object => boom
                        Logger.warn("Unexpected error while syncing #{mailbox}: #{boom}\n#{boom.backtrace.join("\n")}")
                    end
                end
            end
            @initial_size = @procs_queue.size
            @procs_queue.size.times{ @pool.process{ @procs_queue.shift.call }}
        end

        # return percentage of tasks completed
        def progress
            return @procs_queue.size / @initial_size.to_f
        end

        private

        def sync(mailbox)
            source_items = @src_account.mailbox_list.items(mailbox)
            dest_items = @dest_account.mailbox_list.items(mailbox)
            source_items.skip_messages(dest_items.message_ids)
            run = true
            while(run)
                begin
                    message, flags, date = source_items.fetch_next_message
                    if(message.nil?)
                        Logger.warn("Message was nil!")
                        next
                    end
                    dest_items.add_message(message, flags, date)
                rescue MessageDuplicate => boom
                    Logger.warn("Duplicate message found in #{mailbox} with ID: #{boom.message_id}")
                rescue EOFError
                    Logger.info("Reached end of file for mailbox: #{mailbox}")
                    run = false
                rescue EOFolder
                    Logger.info("Reached end of file for mailbox: #{mailbox}")
                    run = false
                rescue IsDirectory => boom
                    Logger.warn("No messages. File is a directory: #{boom.path}")
                    run = false
                end
            end
        end
    end
end