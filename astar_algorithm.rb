require 'colorize'

class Node
  include Comparable
  
  attr_accessor :gCost, :fCost, :parent
  attr_reader   :hCost, :neighbors, :coords

  DELTAS = [[ 1, 0], [0, 1], [-1, 0], [ 0,-1],
            [-1,-1], [1, 1], [ 1,-1], [-1, 1]]

  def initialize(board, coords, parent = nil)
    @board  = board
    @coords = coords 
    @parent = parent
    @hCost  = heuristic
    @gCost  = movement + (parent == nil ? 0 : parent.gCost)
    @fCost  = @gCost + @hCost
  end
  
  def update(newParent)
    @parent = newParent
    @gCost  = movement(newParent)
    @fCost  = @gCost + @hCost
  end

  def neighbors 
    @neighbors = []
    adjacent.each do |row, col|
      if [' ','E'].include?(@board.board[row][col])
        @neighbors << Node.new(@board, [row,col], self) 
      end
    end
    @neighbors
  end
  
  def movement(node = @parent)
    return 0 unless node
    (@coords[0] - node.coords[0]).abs + (coords[-1] - node.coords[-1]).abs == 1 ? 10 : 14
  end
    
  def <=>(node)
    if self.fCost < node.fCost
      -1
    elsif self.fCost > node.fCost
      1
    else
      0
    end
  end

  private
  def heuristic
    (@coords.first - @board.dest.first).abs + 
    (@coords.last - @board.dest.last).abs
  end
  
  def adjacent
    DELTAS.map {|row, col| [row + @coords.first, col + @coords.last] }
  end
end

class Board  
  attr_reader :start, :dest
  attr_accessor :board
  
  def initialize(file)
    create(file)
  end
  
  def mark(coords)
    @board[coords.first][coords.last] = '.'
  end

  def display
    @board.each {|row| puts row.join('') }
  end
  
  def displayColor
    @board.each do |row|
      row.each do |tile|
        if tile == '.'
          print tile.colorize(:red)
        else
          print tile
        end
      end
      puts 
    end
  end
  
  private     
  def create(file)
    @board = []
    IO.foreach(file) do |line|
      chars  = line.chomp.split('')
      @board << chars
      @start  = [$. - 1, chars.index('S')] if chars.index('S')
      @dest   = [$. - 1, chars.index('E')] if chars.index('E')
    end
  end
end

class Astar
  attr_reader :board
  
  def initialize(file = 'astar.txt')
    @board = Board.new(file)
    @startNode = Node.new(@board, @board.start)
    @dest = @board.dest # coordinates [row, col] (not a node)
  end
  
  def inList?(list, n)
    list.any? {|node| node.coords == n.coords }
  end
    
  def algorithm(startNode = @startNode, dest = @dest)
    openList   = [startNode]
    closedList = []
    
    until openList.empty?
      openList.sort!
      current = openList.shift
      closedList << current
            
      return current if current.coords == dest  
        
      current.neighbors.each do |node|
        next if inList?(closedList, node)
          
        if inList?(openList, node)
          node.update(current) if node.fCost > current.fCost + current.movement(node)
        else
          openList << node
        end
      end
    end  
  end
  
  def tracePath(node)
    node = node.parent # Prevents erasure of destination
    until node.parent.nil?
      @board.mark(node.coords)
      node = node.parent
    end
  end
end

astar = Astar.new
node = astar.algorithm
astar.tracePath(node)
astar.board.displayColor


