require "monitor"

class ThreadQueues::StringBuffer
  def initialize(queue)
    @queue = queue
    @buffer = ""
    @mutex = Monitor.new
  end

  def gets
    @mutex.synchronize do
      loop do
        if match = @buffer.match(/\A(.+)\n/)
          @buffer.gsub!(/\A(.+)\n/, "")
          return match[0]
        end

        begin
          store_more_in_buffer
        rescue EOFError => e
          return @buffer if @buffer.length > 0
          raise e
        end
      end
    end
  end

  def read(length)
    @mutex.synchronize do
      loop do
        if @buffer.length >= length
          return @buffer.slice!(0, length)
        end

        begin
          store_more_in_buffer
        rescue EOFError => e
          return @buffer if @buffer.length > 0
          raise e
        end
      end
    end
  end

private

  def store_more_in_buffer
    @mutex.synchronize do
      begin
        @buffer << @queue.pop.to_s
      rescue Exception => e
        raise EOFError, "No live threads left. Deadlock?" if e.message == "No live threads left. Deadlock?"
        raise e
      end
    end
  end
end
