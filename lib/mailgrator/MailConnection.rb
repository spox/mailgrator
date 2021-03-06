['Exceptions', 'Logger'].each{|f| require "mailgrator/#{f}"}
require 'net/imap'
module MailGrator
    class MailConnection
        # server::  IMAP hostname
        # user::    IMAP username
        # pass::    IMAP password
        # port::    IMAP server port
        # secure::  force secure authentication
        # Creates new MailConnection
        def initialize(server, user, pass, port=nil, secure=false)
            @username = user
            @password = pass
            @server = server
            @connection = nil
            @current_box = nil
            @read_only = false
            @secure = secure
            if(port.nil?)
                @port = secure ? 993 : 143
            else
                @port = port
            end
            @lock = Mutex.new
            connect
        end

        # returns Net::IMAP object
        def imap
            if(@connection.nil? || @connection.disconnected?)
                reconnect
            end
            return @connection
        end

        # returns current mailbox
        def current_mailbox
            return @current_box
        end

        # read_only::   set mailbox to read only
        # changes mailbox and will set to readonly
        def change_mailbox(box, read_only=false)
            @current_box = box
            @read_only = read_only
            first = true
            begin
                if(read_only)
                    begin
                        imap.examine(box)
                    rescue Net::IMAP::BadResponseError
                        Logger.warn("Read-only connection to #{box} failed. Connecting directly")
                        imap.select(box)
                    end
                else
                    imap.select(box)
                end
            rescue IOError => boom
                if(first)
                    Logger.warn("Change mailbox failed. Attempting a reconnect and retrying mailbox")
                    first = false
                    reconnect
                    retry
                else
                    Logger.fatal("Failed to change mailbox. Connection error assumed: #{boom}")
                    raise boom
                end
            end
        end

        # mailbox:: destination mailbox for message
        # message:: message to add to mailbox
        # adds message to given mailbox
        def append_message(mailbox, message, flags, date=nil)
            #raise ReadOnlyMailbox.new(mailbox) if @read_only
            @lock.synchronize do

                begin
                    if(message =~ /^(From - ... ... .+?[0-9]{4}\n)/ && date.nil?)
                        timestr = $1
                        message.gsub(/^#{timestr}/, '')
                        timestr.chomp
                        begin
                            date = Time.parse(timestr)
                        rescue
                            date = Time.now
                        end
                    end
                    imap.append(mailbox, message, flags, date)
                    Logger.info("New message added to #{mailbox}")
                rescue Object => boom
                    Logger.warn("Failed to transer message to #{mailbox}: #{boom}")
                end
            end
        end

        private

        def connect
            Logger.info("Attempting connection to IMAP server: #{@server}:#{@port}")
            begin
                @connection = Net::IMAP.new(@server, {:port => @port}, @secure)
                Logger.info('Connection to server has been established')
                authenticate
            rescue Object => boom
                unless(boom.is_a?(ConnectionFailed))
                    boom = ConnectionFailed.new(boom.dup)
                end
                raise boom
            end
        end

        def authenticate
            Logger.info('Determining supported authentication types.')
            types = @connection.capability
            Logger.info("Supported authentication types: #{types.join(', ')}")
            authed = false
            begin
                if(types.include?("AUTH=CRAM-MD5"))
                    Logger.info('Attempting CRAM-MD5 authentication')
                    @connection.authenticate('cram-md5', @username, @password)
                    authed = true
                end
            rescue Object
                Logger.warn('Authentication failed using CRAM-MD5')
            end
            if(!@secure && !@authed)
                begin
                    Logger.info('Attempting direct authentication')
                    @connection.login(@username, @password)
                    authed = true
                rescue
                    Logger.warn('Authentication failed using direct login')
                end
            end
            raise ConnectionFailed.new("Failed to authenticate") unless authed
            Logger.info("Successful authentication to: #{@server}:#{@port}")
        end

        def reconnect
            unless(@connection.nil?)
                begin
                    @connection.close
                rescue Object => boom
                    Logger.warn("Connection threw an error on closing: #{boom}")
                end
            end
            connect
            change_mailbox(@current_box, @read_only) unless @current_box.nil?
        end
    end
end