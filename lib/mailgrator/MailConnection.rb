['Exceptions', 'net/imap'].each{|f| require "mailgrator/#{f}"}
module MailGrator
    class MailConnection
        # server::  IMAP hostname
        # user::    IMAP username
        # pass::    IMAP password
        # port::    IMAP server port
        # secure::  force secure authentication
        # Creates new MailConnection
        def initialize(server, user, pass, port=143, secure=false)
            @username = user
            @password = pass
            @port = port
            @server = server
            @connection = nil
            @current_box = nil
            @read_only = false
            @secure = secure
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
            if(read_only)
                begin
                    @connection.examine(box)
                rescue Net::IMAP::BadResponseError
                    Logger.warn("Read-only connection to #{box} failed. Connecting directly")
                    @connection.select(box)
                end
            else
                @connection.select(box)
            end
        end

        # mailbox:: destination mailbox for message
        # message:: message to add to mailbox
        # adds message to given mailbox
        def append_message(mailbox, message)
            raise ReadOnlyMailbox.new(mailbox) if @read_only
            @lock.synchronize do
                begin
                    date = Time.now
                    if(message =~ /^(From - ... ... .+?[0-9]{4}\n)/)
                        timestr = $1
                        message.gsub(/^#{timestr}/, '')
                        timestr.chomp
                        begin
                            date = Time.parse(timestr)
                        rescue
                            date = Time.now
                        end
                    end
                    @connection.append(mailbox, message, [:SEEN], date)
                    Logger.info("New message added to #{mailbox}")
                rescue Object => boom
                    Logger.warn("Failed to transer message to #{mailbox}: #{boom}")
                end
            end
        end

        private

        def connect
            Logger.info("Attempting connection to IMAP server: #{@server}:#{@port}")
            @connection = Net::IMAP.new(@server, @port)
            Logger.info('Connection to server has been established')
            authenticate
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
                    @connection.login('login', @username, @password)
                    authed = true
                rescue
                    Logger.warn('Authentication failed using direct login')
                end
            end
            raise ConnectionFailed.new(@server, @port) unless @authed
            Logger.info("Successful authentication to: #{@server}:#{@port}")
        end

        def reconnect
            return unless @connection.nil? && @connection.disconnect?
            connect
            change_mailbox(@current_box, @read_only) unless @current_box.nil?
        end
    end
end