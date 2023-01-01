# this class loads the contents of a file using a Ractor so that it's running
# outside your main Ractor.
#
# Usage:
#   rio = RactorIO.new.read('/tmp/a_large_file.txt')  # read a file
#   ... do other stuff ...
#
#   # optional loop until the file is read
#   loop do
#     breadk if rio.ready?
#     sleep 1
#   end
#
#   rio.string    # contains the contents of the file as one large String
class RactorIO
  attr_reader :string

  def initialize
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
        Ractor.yield(IO.read(Ractor.receive), move: true)
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
