class Color
  class Reset
    def self::to_s
      "\e[0m\e[37m"
    end
  end

  class Red < Color
    def num; 31; end
  end
  class Green < Color
    def num; 32; end
  end
  class Yellow < Color
    def num; 33; end
  end

  def self::to_s
    new.to_s
  end

  def to_s
    "\e[1m\e[#{num}m"
  end
end

module Socksify
  def self.debug=(enabled)
    @@debug = enabled
  end

  def self.debug_debug(str)
    debug(Color::Green, str)
  end

  def self.debug_notice(str)
    debug(Color::Yellow, str)
  end

  def self.debug_error(str)
    debug(Color::Red, str)
  end

  private

  def self.debug(color, str)
    if defined? @@debug
      puts "#{color}#{now_s}#{Color::Reset} #{str}"
    end
  end

  def self.now_s
    Time.now.strftime('%H:%M:%S')
  end
end
