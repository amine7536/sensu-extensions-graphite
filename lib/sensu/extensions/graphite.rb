require "sensu/extension"

module Sensu
  module Extension

    ######################################
    # ExponentialDecayTimer
    #
    # Implement an exponential backoff timer for reconnecting to metrics
    # backends.
    ######################################
    class ExponentialDecayTimer
      attr_accessor :reconnect_time

      def initialize
        @reconnect_time = 0
      end

      def get_reconnect_time(max_reconnect_time, connection_attempt_count)
        if @reconnect_time < max_reconnect_time
          seconds = @reconnect_time + (2**(connection_attempt_count - 1))
          seconds = seconds * (0.5 * (1.0 + rand))
          @reconnect_time = if seconds <= max_reconnect_time
                              seconds
                            else
                              max_reconnect_time
                            end
        end
        @reconnect_time
      end
    end

    #########################################
    # Connection Handler
    #########################################
    class ConnectionHandler < EM::Connection

    # XXX: These should be runtime configurable.
    MAX_RECONNECT_ATTEMPTS = 0 # Attempt no reconnects. Drop if it can't in favor for speed.
    MAX_RECONNECT_TIME = 0 # seconds

    attr_accessor :message_queue, :connection_pool
    attr_accessor :name, :host, :port, :connected
    attr_accessor :reconnect_timer

    # ignore :reek:TooManyStatements
    def post_init
      @is_closed = false
      @connection_attempt_count = 0
      @max_reconnect_time = MAX_RECONNECT_TIME
      @comm_inactivity_timeout = 0 # disable inactivity timeout
      @pending_connect_timeout = 30 # seconds
      @reconnect_timer = ExponentialDecayTimer.new
    end

    def connection_completed
      @connected = true
    end

    def close_connection(*args)
      @is_closed = true
      @connected = false
      super(*args)
    end

    def comm_inactivity_timeout
      logger.info("Graphite: Connection to #{@name} timed out.")
      schedule_reconnect
    end

    def unbind
      @connected = false
      unless @is_closed
        logger.info('Graphite: Connection closed unintentionally.')
        schedule_reconnect
      end
    end

    def send_data(*args)
      super(*args)
    end

    # Override EM::Connection.receive_data to prevent it from calling
    # puts and randomly logging non-sense to sensu-server.log
    def receive_data(data)
    end

    # Reconnect normally attempts to connect at the end of the tick
    # Delay the reconnect for some seconds.
    def reconnect(time)
      EM.add_timer(time) do
        logger.info("Graphite: Attempting to reconnect relay channel: #{@name}.")
        super(@host, @port)
      end
    end

    def get_reconnect_time
      @reconnect_timer.get_reconnect_time(
        @max_reconnect_time,
        @connection_attempt_count
      )
    end

    def schedule_reconnect
      unless @connected
        @connection_attempt_count += 1
        reconnect_time = get_reconnect_time
        logger.info("Graphite: Scheduling reconnect in #{@reconnect_time} seconds for relay channel: #{@name}.")
        reconnect(reconnect_time)
      end
      reconnect_time
    end

    def logger
      Sensu::Logger.get
    end

  end # ConnectionHandler

  ##########################################
  # EndPoint
  # An endpoint is a backend metric store. This is a compositional object
  # to help keep the rest of the code sane.
  ##########################################
  class Endpoint

    # EM::Connection.send_data batches network connection writes in 16KB
    # We should start out by having all data in the queue flush in the
    # space of a single loop tick.
    MAX_QUEUE_SIZE = 2048

    attr_accessor :connection, :queue

    def initialize(name, host, port)
      @queue = []
      @connection = EM.connect(host, port, ConnectionHandler)
      @connection.name = name
      @connection.host = host
      @connection.port = port
      @connection.message_queue = @queue
      EventMachine::PeriodicTimer.new(60) do
        Sensu::Logger.get.info("Graphite: queue size for #{name}: #{queue_length}")
      end
    end

    def queue_length
      @queue
        .map(&:bytesize)
        .reduce(:+) || 0
    end

    def flush_to_net
      sent = @connection.send_data(@queue.join)
      @queue = [] if sent > 0
    end

    def relay_event(data)
      if @connection.connected
        @queue << data
        if queue_length >= MAX_QUEUE_SIZE
          flush_to_net
          Sensu::Logger.get.debug('Graphite: successfully flushed to network')
        end
      end
    end

    def stop
      if @connection.connected
        flush_to_net
        #@connection.close_connection_after_writing
        @connection.close_connection # Force connection closing, do not wait.
      end
    end

  end


  #################################
  # Graphite Handler
  #################################
  class Graphite < Handler

    def initialize
      super
      @initialized = false
      @counter = 0
    end

    def name
      "graphite"
    end

    def description
      "Extension to get metrics into Graphite"
    end

    def post_init
      @endpoint = Endpoint.new(
        @settings[:graphite][:name],
        @settings[:graphite][:host],
        @settings[:graphite][:port]
      )
      @counter = 0
    end

    def run(event)
      begin
        event = Oj.load(event)
        metrics = event["check"]["output"]
      rescue => e
        logger.error("Graphite: Error setting up event object - #{e.backtrace.to_s}")
      end

      begin
        if @counter > 2048
          logger.debug("Graphite: recycling connection")
          stop
          post_init
        end

        logger.debug("Metrics: #{metrics}")
        @endpoint.relay_event(metrics)
        @counter += 1
      rescue => e
        logger.error("Graphite: Error posting metrics - #{e.backtrace.to_s}")
      end

      yield "", 0
    end

    def stop
      @endpoint.stop
    end

  end # Graphite
  #################################

  end
end