require "gtk2"
require "yaml"

TimerStruct = Struct.new :minutes, :text, :color

class MainWindow < Gtk::Window
  def initialize(yaml)
    super()
    @running = false
    @config = collect_structures YAML.load(yaml)
    @parameters = @config.dup
    draw_screen
    connect_events
  end

  def collect_structures(hash)
    timers = hash.collect do |minutes, attrs|
      if attrs.is_a?(Hash)
        TimerStruct.new minutes, attrs['text'], attrs['color']
      else
        TimerStruct.new minutes, attrs
      end
    end
    timers.sort_by { |t| t.minutes }
  end
  private :collect_structures

  def draw_screen
    modify_bg Gtk::STATE_NORMAL, Gdk::Color.new(0,0,0)
    hbox = Gtk::HBox.new
    hbox.add @start_pause = Gtk::Button.new('Start')
    hbox.add @reset = Gtk::Button.new('Reset')
    vbox = Gtk::VBox.new
    add vbox
    vbox.add hbox
    vbox.add(@clock = Gtk::Label.new)
    vbox.add(@label = Gtk::Label.new)
    @clock.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse('white')
    reset_clock_text
  end
  private :draw_screen

  def connect_events
    @start_pause.signal_connect('clicked') { start_pause_clock }
    @reset.signal_connect('clicked') { reset_clock }
    signal_connect('destroy') { Gtk.main_quit }
  end
  private :connect_events

  def reset_clock
    stop_clock
    @timer = nil
    reset_clock_text
  end

  def reset_clock_text
    @clock.text = '00:00'
    @clock.modify_font Pango::FontDescription.new('Verdana Bold 78')
    @clock.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse('white')
    @label.text = ''
    @label.modify_font Pango::FontDescription.new('Verdana Bold 16')
    @label.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse('white')
  end
  private :reset_clock_text

  def start_pause_clock
    if running?
      stop_clock
    else
      start_clock
    end
  end

  def running?
    @start_pause.label == 'Pause'
  end
  private :running?

  def start_clock
    @start_pause.label = 'Pause'
    start_or_create_clock
    GLib::Timeout.add(500) { update_clock }
  end
  private :start_clock

  def update_clock
    return unless running?
    @clock.text = convert_to_hours
    if @parameters[0] && @timer.elapsed[0] >= @parameters[0].minutes 
      actual = @parameters.delete_at 0
      @label.text = actual.text if actual.text

      if actual.color
        actual.color = "##{actual.color}" if actual.color =~ /^([A-F\d]{3})+$/
        color = Gdk::Color.parse(actual.color) rescue Gdk::Color.parse('white')
        @label.modify_fg Gtk::STATE_NORMAL, color 
        @clock.modify_fg Gtk::STATE_NORMAL, color 
      end
    end
    return true
  end

  def stop_clock
    @start_pause.label = 'Start'
    @timer.stop
  end
  private :stop_clock

  def start_or_create_clock
    if @timer.nil?
      @timer ||= GLib::Timer.new
      @parameters = @config.dup
    else
      @timer.continue
    end
  end
  private :start_or_create_clock

  def convert_to_hours
    sec, mili = @timer.elapsed
    sec = sec.to_i
    min, sec = sec / 60, sec % 60
    min, sec = min.to_s, sec.to_s
    min, sec = min.rjust(2, '0'), sec.rjust(2, '0')
    return "#{min}:#{sec}"
  end
  private :convert_to_hours
end

if $0 == __FILE__
  if ARGV.size != 1
    puts "Usage: #$0 configuration.yml"
    exit 1
  end

  mw = MainWindow.new(File.read(ARGV[0]))
  mw.show_all
  Gtk.main
end
