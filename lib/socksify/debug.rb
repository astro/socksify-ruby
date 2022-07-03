# namespace
module Socksify
  # rubocop:disable Style/Documentation
  class Color
    class Reset
      def self.to_s
        "\e[0m\e[37m"
      end
    end

    class Red < Color
      def num
        31
      end
    end

    class Green < Color
      def num
        32
      end
    end

    class Yellow < Color
      def num
        33
      end
    end
    # rubocop:enable Style/Documentation

    def self.to_s
      new.to_s
    end

    def num
      0
    end

    def to_s
      "\e[1m\e[#{num}m"
    end
  end

  def self.debug=(enabled)
    @debug = enabled
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

  def self.debug(color, str)
    puts "#{color}#{now_s}#{Color::Reset} #{str}" if defined?(@debug) && @debug
  end

  def self.now_s
    Time.now.strftime('%H:%M:%S')
  end
end
