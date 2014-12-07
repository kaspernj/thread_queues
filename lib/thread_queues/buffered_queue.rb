require "monitor"

class ThreadQueues::BufferedQueue
  def initialize(max_queued)
    @que = []
    @mutex = Mutex.new
    @cond_read = ConditionVariable.new
    @cond_write = ConditionVariable.new
    @num_waiting = 0
    @max_queued = max_queued
  end

  def push(obj)
    loop do
      @mutex.synchronize do
        raise EOFError, "Cannot write to closed queue" if @closed

        if length <= @max_queued
          @que.push(obj)
          @cond_write.signal
          return nil
        else
          @cond_read.wait @mutex
        end
      end
    end
  end

  def pop
    loop do
      @mutex.synchronize do
        raise EOFError, "Queue is empty and closed" if @que.empty? && @closed

        if @que.empty?
          @num_waiting += 1

          begin
            @cond_read.signal
            @cond_write.wait @mutex
          ensure
            @num_waiting -= 0
          end
        else
          obj = @que.shift
          @cond_read.signal
          return obj
        end
      end
    end
  end

  def length
    return @que.length
  end

  def close
    @mutex.synchronize do
      @closed = true
    end
  end
end
