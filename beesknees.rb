require 'rubygems'
require 'redis'
require 'sinatra'
require 'activesupport'
require 'haml'
require 'json'

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

SCORES = {
  3 => 1,
  4 => 1,
  5 => 2,
  6 => 3,
  7 => 5,
  8 => 11
}

def find_indices(letters, this_letter)
  found = []
  letters.map(&:upcase).each_with_index do |letter, index|
    found << index if letter == this_letter
  end
  found
end

class Node
  attr_accessor :index
  attr_accessor :letter
  attr_accessor :children

  def initialize(index, letter)
    @index = index
    @letter = letter
    @children = []
  end

  def find(roll, check_word)
    adj = ADJACENTS[@index].map { |n| roll[n] }
    next_indices = find_indices(adj, check_word.first)
    next_nodes = next_indices.map { |s| ADJACENTS[@index][s] }
    next_nodes.each do |node|
      next_roll = roll.dup
      next_roll[node] = '?'

      node = Node.new(node, check_word.first)
      self.children << node
      node.find(next_roll, check_word[1..-1]) if check_word.size > 1
    end
  end

  def size
    if children.size == 0
      return 1
    else
      return 1 + children.map(&:size).max
    end
  end
end

class BeesKnees
  KEY = 'beesknees:dict'

  def log(message)
    puts "[#{Time.now}] #{message}"
  end

  def self.load
    $redis.delete KEY
    all_words = File.readlines("/usr/share/dict/words")
    words = all_words.select { |word| word =~ /^[a-z]{3,8}$/ }
    words.each { |word| $redis.set_add KEY, word.chomp.upcase }
  end

  def self.roll
    id = $redis.incr 'beesknees:game'
    key = "beesknees:game:#{id}"
    DICE.map(&:rand).shuffle.each do |roll|
      $redis.push_tail key, roll
    end
    id
  end

  def self.find(id)
    $redis.list_range("beesknees:game:#{id}", 0, -1)
  end

  def self.score(id)
    $redis["beesknees:score:#{id}"] || 0
  end

  def self.score!(id, score)
    $redis["beesknees:score:#{id}"] = score
  end

  def self.word?(word)
    $redis.set_member?(KEY, word)
  end

  def self.in?(id, word)
    roll = find(id)

    chars = word.chars.to_a
    if word =~ /QU/
      q_index = chars.index("Q")

      chars = chars[0...q_index] +
              %w[QU] +
              chars[q_index + 2..-1]
    end

    find_indices(roll, chars.first).each do |start|
      next_roll = roll.dup
      next_roll[start] = "?"
      parent = Node.new(start, chars.first)

      parent.find(next_roll, chars[1..-1])
      return true if parent.size == chars.size
    end
    false
  end

  def self.valid?(id, word)
    valid = word?(word) && in?(id, word)

    if valid
      $redis.set_add "beesknees:success:#{id}", word
    else
      $redis.set_add "beesknees:error:#{id}", word
    end

    valid
  end

  def self.log(id)
    {
      :success => $redis.set_members("beesknees:success:#{id}"),
      :error   => $redis.set_members("beesknees:error:#{id}")
    }
  end

  def self.dupe?(id, word)
    $redis.set_member?("beesknees:success:#{id}", word) ||
    $redis.set_member?("beesknees:error:#{id}", word)
  end
end

get '/' do
  id = BeesKnees.roll
  redirect "/#{id}"
end

get '/:id' do
  id = params[:id]

  @roll = BeesKnees.find(id).in_groups_of(4)
  @score = BeesKnees.score(id)
  @log = BeesKnees.log(id)

  haml :index
end

post '/' do
  guess = params[:guess].upcase
  id = params[:id]
  score = BeesKnees.score(id).to_i

  result = if BeesKnees.dupe?(id, guess)
    'dupe'
  elsif BeesKnees.valid?(id, guess)
    score += SCORES[guess.size]
    BeesKnees.score!(id, score)
    'success'
  else
    'error'
  end

  content_type "application/json"
  {
    :guess  => guess,
    :score  => score,
    :result => result
  }.to_json
end
