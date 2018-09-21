INTERVAL = 0.05
ALIVE = "*"
DEAD = " "

Signal.trap(:INT){ puts; exit 0 }

class Lifegame
  def initialize
    @height, @width = `stty size`.split.map &:to_i
    set_random_field
    @generation = 0
  end

  def set_random_field
    @field = Array.new(@height){ Array.new(@width){ rand(2) == 1 } }
  end

  def draw
    print @field.map{|row| row.map{|cell| cell ? ALIVE : DEAD }.join } * "\n"
  end

  def get_cell(row, col)
    @field[row][col]
  end

  def get_neighbors(row, col)
    (-1..1).map do |i|
      r = row + i #みているcellの行と上下の行に対して処理
      r -= @height if r >= @height #上と下をつなぐ
      (-1..1).map do |j|
        c = col + j
        c -= @width if c >= @width
        @field[r][c]
      end
    end
  end

  def count_neighbors(cell, row, col)
    neighbors = get_neighbors(row, col)
    neighbors.flatten.count(true) + (cell ? -1 : 0)
  end

  def next_status(row, col)
    cell = get_cell(row, col)
    neighbors = count_neighbors(cell, row, col)
    judge(cell, neighbors)
  end

  def judge(cell, neighbors)
    # セルが生存している時 => 周囲の生存セルが2つ or 3つだったら生存し続ける
    # セルが死んでいる時 => 周囲の生存セルがちょうど3つだったら生まれる
    # それ以外なら死ぬ
    cell ? neighbors.between?(2, 3) : neighbors == 3
  end

  def advance #ターンを進める
    @generation += 1
    @field = Array.new(@height){|row| Array.new(@width){|col| next_status(row, col) } }
  end

  def active_cells
    @field.flatten.count true #flatten the 2 * 2 Array and count the active(true) cells
  end

  def to_top_left
    print "\e[1;1H"
  end

  def to_bottom_left
    print "\e[#{@height};1H"
  end

  def print_status
    print "%5d generation, %5d cells alive. " % [@generation, active_cells]
  end

  def to_bottom_right
    print "\e[#{@height};#{@width}H" #(やったほうが美しい)
  end

  def run(interval = INTERVAL)
    puts "\e[2J" #画面消去
    loop do
      start_time = Time.now.to_f #更新開始

      to_top_left
      draw
      to_bottom_left
      print_status
      to_bottom_right
      advance

      stop_time = Time.now.to_f #更新終了
      elapsed = stop_time - start_time #作業にかかった時間

      #スリープ (画面が大きいと割とモッサリするから作業時間はインターバルからマイナスする)
      sleep interval < elapsed ? 0 : interval - elapsed
    end
  end
end

Lifegame.new.run
