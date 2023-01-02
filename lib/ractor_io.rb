# this class loads the contents of a file using a Ractor so that it's running
# outside your main Ractor.
#
# Usage:
#   rio = RactorIO.new.read('/tmp/a_large_file.txt')  # read a file
#   ... do other stuff ...
#
#   # optional loop until the file is read
#   loop do
#     break if rio.ready?
#     sleep 1
#   end
#
#   rio.string    # contains the contents of the file as one large String
class RactorIO
  attr_reader :string

  # move: if true, the Ractor will yield the loaded file using the `move` option of Ractor::yield.
  #   default: false
  #
  #   NOTE: as of this writing, and having tested this against Ruby 3.1.x and
  #   3.2.x, setting the `move` option to `true' for large amounts of data
  #   seems to cause a crash, at least on macOS. as a result this option is set
  #   to `false` by default, which will result in a lot of memory copying, and
  #   therefore increasing total memory consumption.
  #
  #   In the meantime, see also https://github.com/jefflunt/thread_io -
  #   basically the same library as this, but using Threads only instead of
  #   Ractors, which has the advantage of sharing memory, if that's important to
  #   you. I haven't done extensive performance testing, so the perfornace
  #   difference between ractor_io and thread_io might not be very large for
  #   your particular use case.
  def initialize(move: false)
    @move = move
    @ready = false
    @string = nil
  end

  # this method returns immediately and loads the file in the background
  #
  # path: the path to the file you want to read.
  def read(path)
    Thread.new do
      @ready = false
      @string = nil
      r = Ractor.new do
        Ractor.yield(IO.read(Ractor.receive), move: @move)
      end
      r.send(path)
      @string = r.take
      @ready = true

      nil
    end

    nil
  end

  def ready?
    @ready
  end
end
