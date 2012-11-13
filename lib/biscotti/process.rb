require 'stringio'

module Biscotti

  class Process

    PROCESS_TIMEOUT = 5
    ProcessTimeout = Class.new(StandardError)

    class IOWriter

      def initialize io, source
        @io, @source = io, source
      end

      def call
        @thr = Thread.new do
          begin
            @source.each { |data| @io.write(data) }
          ensure
            @io.close
          end
        end
      end

      def join
        @thr.join
      end

    end

    class IOReader

      READ_SIZE = 1024

      def initialize io, &block
        @io = io
        @block = block
      end

      def call
        @thr = Thread.new do
          begin
            loop { @block.call( @io.readpartial(READ_SIZE)) }
          rescue EOFError
            nil
          ensure
            @io.close
          end
        end
      end

      def join
        @thr.join
      end

    end

    class IOBufferedReader

      READ_SIZE = 1024

      def initialize io
        @io = io
      end

      def call
        @thr = Thread.new do
          Thread.current[:value] = StringIO.new
          begin
            loop { Thread.current[:value] << @io.readpartial(READ_SIZE) }
          rescue EOFError
            nil
          ensure
            @io.close
          end
        end
      end

      def join
        @thr.join
      end

      def value
        @thr.join
        @thr[:value].string
      end

    end

    module BiscottiIO

      def biscotti
        @biscotti
      end

      def value
        @biscotti.value
      end

    end

    def initialize &block
      @block = block
    end

    def run
      instance_eval &@block
    end

    def timeout t
      @timeout = t
    end

    def input source
      rd,wr = IO.pipe
      o = IOWriter.new(wr, source)
      decorate_io rd, o
    end

    def output &block
      rd, wr = IO.pipe
      o = IOReader.new(rd, &block)
      decorate_io wr, o
    end

    def buffered_output
      rd, wr = IO.pipe
      o = IOBufferedReader.new(rd)
      decorate_io wr, o
    end


    def command *cmd
      @output_ios = recursively_flatten(cmd).find_all { |i| i.respond_to?(:biscotti) }
      pid = ::Process.spawn *map_biscotti_ios_for_spawn(cmd)
      status = nil
      ensure_threads_abort_on_exception do
        @output_ios.each {|io| io.biscotti.call}
        status = wait_for_process pid
        @output_ios.each(&:close)
      end
      [status] + @output_ios.find_all { |io| io.biscotti.respond_to?(:value) }.map { |io| io.value }
    end



    private

    def ensure_threads_abort_on_exception
      orig = Thread.abort_on_exception
      Thread.abort_on_exception = true
      yield
      Thread.abort_on_exception = orig
    end

    def decorate_io io, o
      io.extend BiscottiIO
      io.instance_variable_set(:@biscotti, o)
      io
    end

    def map_biscotti_ios_for_spawn array
      array.map { |o| o.respond_to?(:biscotti) ? "/proc/#{::Process.pid}/fd/#{o.fileno}" : o }
    end

    def wait_for_process pid
      timeout = Thread.new { sleep (@timeout || PROCESS_TIMEOUT); ::Process.kill(9, pid); raise ProcessTimeout }
      thr = Thread.new { x, Thread.current[:status] = ::Process.wait2(pid); timeout.kill }
      thr.join
      thr[:status]
    end

    # Recursively flattens everything flatten-able.  Including Hashes.
    def recursively_flatten obj
      buffer = Array[obj]
      result = []
      while o = buffer.shift
        if o.respond_to?(:flatten)
          buffer +=  o.flatten
        else
          result << o
        end
      end
      result
    end

  end

end
