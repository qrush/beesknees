require 'rubygems'
require 'redis'
require 'sinatra'
require 'activesupport'
require 'haml'
require 'pp'

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
    words.each { |word| $redis.set_add KEY, word.chomp }
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
    $redis.list_range("doggles:game:#{id}", 0, -1)
  end

  def self.word?(word)
    $redis.set_member?(KEY, word)
  end

  ADJACENTS = { 
    0  => [1, 4, 5],
    1  => [0, 2, 4, 5, 6],
    2  => [1, 3, 5, 6, 7],
    3  => [2, 6, 7],
    4  => [0, 1, 5, 8, 9],
    5  => [0, 1, 2, 4, 6, 8, 9, 10],
    6  => [1, 2, 3, 5, 7, 9, 10, 11],
    7  => [2, 3, 6, 10, 11],
    8  => [4, 5, 9, 12, 13],
    9  => [4, 5, 6, 8, 10, 12, 13, 14],
    10 => [5, 6, 7, 9, 11, 13, 14, 15],
    11 => [6, 7, 10, 14, 15],
    12 => [8, 9, 13],
    13 => [8, 9, 10, 12, 14],
    14 => [9, 10, 11, 13, 15],
    15 => [10, 11, 14]
  }

  def self.in?(id, word)
    roll = find(id)
    grid = roll.in_groups_of(4)

    starting = find_indices(roll, word.first)
        #p "FOUND #{letter}"
        #pp index
        #pp adj
        #pp adj.map { |n| roll[n] }

    if starting.empty?
      false
    else
      starting.each do |start|
        check_word = word.chars.to_a[1..-1]
        return true if next_to?(roll, start, check_word)
      end
      false
    end
  end

  def self.find_indices(letters, this_letter)
    found = []
    letters.each_with_index do |letter, index|
      found << index if letter == this_letter
    end
    found
  end

  def self.next_to?(roll, start, check_word)
    return true if check_word.empty?

    adj = ADJACENTS[start].map { |n| roll[n] }
    if adj.include?(check_word.first)
      next_indices = find_indices(adj, check_word.first)
      next_starts = next_indices.map { |s| ADJACENTS[start][s] }

      return next_to?(roll, next_starts.first, check_word[1..-1])
    else
      return false
    end
  end

  def self.valid?(id, word)
    word?(word) && in?(id, word)
  end
end

get '/' do
  id = Doggles.roll
  redirect "/#{id}"
end

get '/:id' do
  @roll = Doggles.find(params[:id]).in_groups_of(4)
  haml :index
end

post '/' do
  @guess = params[:guess]

  if Doggles.valid?(params[:id], @guess.upcase)
    status 201
  else
    status 403
  end

  @guess
end
