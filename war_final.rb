class Game
  def start
    setup and play
  end
  
  def setup
    deck = Deck.new
    deck.shuffle!
    
    @players = [
      Player.new(deck.first(26)),
      Player.new(deck.last(26))
    ]
  end
  
  def play
    @rounds = 0
    loop do
      @rounds += 1
      stack = Stack.new do
        @players.map(&:draw)
      end
      
      @players[stack.winner] << stack.flatten
    end
  rescue Player::Defeat
    finish
  end
  
  def finish
    winner = @players.find(&:victory?)
    puts "#{ winner } is victorious in #{ @rounds } rounds!"
  end
end

class Stack < Array
  def initialize
    loop do
      self << yield
      break unless tie?
      3.times { self << yield }
    end
  end
  
  def tie?
    last.reduce(&:<=>) == 0
  end
  
  def winner
    last.index(last.max)
  end
end

class Player
  Defeat = Class.new(Exception)
  
  @@next_id = 0
  def initialize(deck)
    @deck = deck
    @id = (@@next_id += 1)
  end
  
  def draw
    @deck.shift or raise Defeat
  end
  
  def <<(cards)
    @deck += cards.shuffle
  end
  
  def victory?
    @deck.size > 0
  end
  
  def to_s
    "Player #{ @id }"
  end
end

class Deck < Array
  def initialize
    Card::FACES.each do |f|
      Card::SUITS.each do |s|
        self << Card.new(f, s)
      end
    end
  end
end

class Card
  attr_accessor :face, :suit
  FACES = %w{2 3 4 5 6 7 8 9 T J Q K A}
  SUITS = %w{C H D S}
  
  def initialize(face, suit)
    @face = face
    @suit = suit
  end
  
  def <=>(other)
    face <=> other.face
  end
  
  def face
    FACES.index(@face)
  end
  
  def inspect
    "#<Card #{ @face }#{ @suit }>"
  end
end