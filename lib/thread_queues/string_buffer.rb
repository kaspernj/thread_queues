require "monitor"

class ThreadQueues::StringBuffer
  attr_reader :lineno, :pos

  def initialize(queue)
    @queue = queue
    @buffer = ""
    @mutex = Monitor.new
    @lineno = 0
    @pos = 0
  end

  def gets(sep = "\n", limit = nil)
    if limit == nil && !sep.is_a?(String)
      limit = sep
      sep = "\n"
    end

    @mutex.synchronize do
      loop do
        if match = @buffer.match(/\A([\s\S]+)#{Regexp.escape(sep)}/)
          take = match[0]
          if limit && take.length > limit
            take = take.slice(0, limit)
          end

          @buffer.gsub!(/\A#{Regexp.escape(take)}/, "")
          @lineno += 1
          @pos += match[0].bytesize
          return take
        end

        begin
          store_more_in_buffer
        rescue EOFError => e
          return rest_of_buffer if @buffer.length > 0
          raise e
        end
      end
    end
  end

  def each_line(&blk)
    with_enumerator(blk) do |y|
      begin
        loop do
          y << gets
        end
      rescue EOFError
      end
    end
  end

  def each_char(&blk)
    with_enumerator(blk) do |y|
      each_chunk do |chunk|
        chunk.each_char do |char|
          y << char
        end
      end
    end
  end

  def each_byte(&blk)
    with_enumerator(blk) do |y|
      each_chunk do |chunk|
        chunk.each_byte do |byte|
          y << byte
        end
      end
    end
  end

  def read(length = nil)
    return read_all if length == nil

    @mutex.synchronize do
      loop do
        if @buffer.length >= length
          content = @buffer.slice!(0, length)
          @pos += content.bytesize
          return content
        end

        begin
          store_more_in_buffer
        rescue EOFError => e
          return rest_of_buffer if @buffer.length > 0
          raise e
        end
      end
    end
  end

  def empty?
    if @pos == 0 && !@closed
      begin
        store_more_in_buffer
      rescue EOFError
      end
    end

    @pos == 0 && @buffer.empty?
  end

private

  def read_all
    str = ""
    each_line do |line|
      str << line
    end

    return str
  end

  def rest_of_buffer
    buffer = @buffer
    @buffer = ""
    @pos += buffer.bytesize
    return buffer
  end

  def each_chunk
    begin
      loop do
        begin
          content = @queue.pop.to_s
          @pos += content.bytesize
          yield content
        rescue Exception => e
          raise EOFError, "No live threads left. Deadlock?" if e.message == "No live threads left. Deadlock?"
          raise e
        end
      end
    rescue EOFError
    end
  end

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

  def with_enumerator(blk)
    enum = Enumerator.new do |y|
      yield(y)
    end

    if blk
      enum.each(&blk)
    else
      enum
    end
  end
end
