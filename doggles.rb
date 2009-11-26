require 'rubygems'
require 'redis'
require 'sinatra'
require 'activesupport'
require 'haml'

$redis = Redis.new

DICE = [
  %w[t i e s o s],
  %w[p c s o a h],
  %w[i t t d y s],
  %w[e e i n s u],
  %w[e r t v h w],
  %w[f p a f k s],
  %w[n m u h qu i],
  %w[u t m o i c],
  %w[e a e n a g],
  %w[n h g w e e],
  %w[n l z h r n],
  %w[e t y l r t],
  %w[e v y d r l],
  %w[x i l r e d],
  %w[b o o j b a],
  %w[o a w t t o]
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
    DICE.map(&:rand).shuffle.in_groups_of(4)
  end
end

  #$redis.set_members Doggles::KEY
get '/' do
  @roll = Doggles.roll
  haml :index
end

__END__

@@index
%table
  -@roll.each do |row|
    %tr
      -row.each do |cell|
        %td= cell

@@layout
%html
%title Doggles.
%body
  %h1 Doggles.
  =yield
