# This class controls the flow of the game
class Game
  # We decided not to start immediately on instantiation, but let the user start
  # it manually
  def start
    setup and play
  end
  
  # Set up the game. Just like you would in real life. Get the deck, shuffle it,
  # and divide it between the two players.
  def setup
    deck = Deck.new
    deck.shuffle!
    
    @players = [
      Player.new(deck.first(26)),
      Player.new(deck.last(26))
    ]
  end
  
  def play
    # Keeping track of how many rounds for fun.
    @rounds = 0
    # The game goes on forever until someone throws an exception saying they
    # lost
    loop do
      @rounds += 1
      # So we start a new stack, and each time the stack asks for some cards, we
      # give him one from each
      stack = Stack.new do
        @players.map(&:draw)
      end
      
      # When the stack is over, we take the whole stack and give it to that
      # player
      @players[stack.winner] << stack.flatten
    end
  rescue Player::Defeat
    # Game is over
    finish
  end
  
  def finish
    winner = @players.find(&:victory?)
    puts "#{ winner } is victorious in #{ @rounds } rounds!"
  end
end

# A stack is basically a single round. You start with one card from each, and if
# they don't tie, the stack is over and control returns to the game. If they do
# tie, they each throw down 3 cards and then repeat with a single card.
class Stack < Array
  def initialize
    loop do
      self << yield
      break unless tie?
      3.times { self << yield }
    end
  end
  
  # This is fancy-talk. self.last is going to be an array of two cards, so by
  # reducing it we're basically doing (last[0] <=> last[1]). Remember 0 means
  # they are equal.
  def tie?
    last.reduce(&:<=>) == 0
  end
  
  # We defined <=>, so we can see who has the higher card, but then we want to
  # see which person (read: index) it belongs to
  def winner
    last.index(last.max)
  end
end

class Player
  # This is an awesome way to define empty classes
  Defeat = Class.new(Exception)
  
  # This is to give each player an id. It's an instance variable, so all players
  # have reference to it.
  @@next_id = 0
  def initialize(deck)
    @deck = deck
    @id = (@@next_id += 1)
  end
  
  # shift returns nil if the array (deck) is empty. If it does return nil,
  # then we raise Defeat ending the game
  def draw
    @deck.shift or raise Defeat
  end
  
  # We use << here since it looks better (like hey, these cards are going to
  # this player), but in reality we need to append two arrays, so we have to use
  # +=. We also shuffle them so that we don't get any cyclical games. It happens
  # quite a lot, actually.
  def <<(cards)
    @deck += cards.shuffle
  end
  
  # Since you could run out in the middle of a stack, the winner may not have
  # all 52 cards, but you know for sure the loser has 0, so you take advantage
  # of that.
  def victory?
    @deck.size > 0
  end
  
  # For victory printing
  def to_s
    "Player #{ @id }"
  end
end

# A deck is just an array of cards. We give it a nice initializer so that it
# builds out a standard deck with a card of each FACE and SUIT
class Deck < Array
  def initialize
    Card::FACES.each do |f|
      Card::SUITS.each do |s|
        self << Card.new(f, s)
      end
    end
  end
end

# We could do this in an awesome way by using 
#   class Card < Struct.new(:face, :suit)
# but I avoided it during the talk because repl.it would complain every time we
# ran it that the parent was changing.
class Card
  # We actually don't need this anymore. We never actually care about suit, and
  # we already defined a custom interface for face.
  attr_accessor :face, :suit
  FACES = %w{2 3 4 5 6 7 8 9 T J Q K A}
  SUITS = %w{C H D S}
  
  def initialize(face, suit)
    @face = face
    @suit = suit
  end
  
  # To compare, we compare faces
  def <=>(other)
    face <=> other.face
  end
  
  # ...but not just faces, since they're strings. So we changed the accessor so
  # that it returns the internal value for it.
  def face
    FACES.index(@face)
  end
  
  # This is just so that debugging is easier, since you are dumping 52 cards to
  # your screen at the same time.
  def inspect
    "#<Card #{ @face }#{ @suit }>"
  end
end
