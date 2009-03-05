['MailAccount', 'Exceptions', 'Logger'].each{|f|require "mailgrator/#{f}"}
require 'thread'

module MailGrator
    class MailSync
        # max_threads:: max number of threads to create
        # Creates new MailSync
        def initialize(max_threads=10)
            @src_account = nil
            @dest_account = nil
            @max_threads = max_threads > 0 ? max_threads : 1
            @threads = []
            @proc_queue = Queue.new
            @stopper = ConditionVariable.new
            @lock = Mutex.new
            @pop_lock = Mutex.new
            @initial_size = 0
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
            @threads = Array.new
            missing_folders = @dest_account.mailbox_list.missing(@src_account.mailbox_list.list)
            @dest_account.mailbox_list.add_mailboxes(missing_folders)
            @src_account.mailbox_list.list.sort do |mailbox|
                @proc_queue << lambda do
                    begin
                        sync(mailbox)
                    rescue Object => boom
                        Logger.warn("Unexpected error while syncing #{mailbox}: #{boom}")
                    end
                end
            end
            @initial_size = @proc_queue.size
            start_threads
            wait_for_completion
        end

        # return percentage of tasks completed
        def progress
            return @proc_queue.size / @initial_size.to_f
        end

        private

        def get_next_proc
            @pop_lock.synchronize do
                return @proc_queue.empty? ? nil : @proc_queue.pop
            end
        end

        def wait_for_completion
            @lock.synchronize do
                @stopper.wait(@lock)
            end
        end

        def notify_completion
            @threads.delete(Thread.self)
            dead_threads = []
            @threads.each{|t| dead_threads.push(t) unless t.alive?}
            if(@threads.size < 1)
                @lock.synchronize do
                    @stopper.wakeup
                end
            end
        end

        def start_threads
            @max_threads.times do
                @threads << Thread.new do
                    cur_proc = get_next_proc
                    until(proc.nil?) do
                        cur_proc.pop.run
                        cur_proc = get_next_proc
                    end
                    notify_completion
                end
            end
        end

        def sync(mailbox)
            source_items = @src_account.mailbox_list.items(mailbox)
            dest_items = @dest_account.mailbox_list.items(mailbox)
            source_items.skip_messages(dest_items.message_ids)
            run = true
            while(run)
                begin
                    message = source_items.fetch_next_message
                    dest_items.add_message(message)
                rescue MessageDuplicate => boom
                    Logger.warn("Duplicate message found in #{mailbox} with ID: #{boom.message_id}")
                rescue EOFError
                    Logger.info("Reached end of file for mailbox: #{mailbox}")
                    run = false
                rescue IsDirectoryError => boom
                    Logger.warn("No messages. File is a directory: #{boom.path}")
                    run = false
                end
            end
        end
    end
end