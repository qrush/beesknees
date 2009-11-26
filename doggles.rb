require 'rubygems'
require 'redis'
require 'sinatra'
require 'activesupport'
require 'haml'

$redis = Redis.new

DICE = [
  %W[T I E S O S],
  %W[P C S O A H],
  %W[I T T D Y S],
  %W[E E I N S U],
  %W[E R T V H W],
  %W[F P A F K S],
  %W[N M U H Qu I],
  %W[U T M O I C],
  %W[E A E N A G],
  %W[N H G W E E],
  %W[N L Z H R N],
  %W[E T Y L R T],
  %W[E V Y D R L],
  %W[X I L R E D],
  %W[B O O J B A],
  %W[O A W T T O]
]

class Doggles
  KEY = 'doggles:dict'

  def log(message)
    puts "[#{Time.now}] #{message}"
  end

  def self.load
    $redis.delete KEY
    all_words = File.readlines("/usr/share/dict/words")
    words = all_words.select { |word| word =~ /^[a-z]{3,8}$/ }
    words.each { |word| $redis.set_add KEY, word }
  end

  def self.roll
    id = $redis.incr 'doggles:game'
    key = "doggles:game:#{id}"
    DICE.map(&:rand).shuffle.each do |roll|
      $redis.push_tail key, roll
    end
    id
  end

  def self.find(id)
    $redis.list_range("doggles:game:#{id}", 0, -1).in_groups_of(4)
  end
end

  #$redis.set_members Doggles::KEY
get '/' do
  id = Doggles.roll
  redirect "/#{id}"
end

get '/:id' do
  @roll = Doggles.find(params[:id])
  haml :index
end
