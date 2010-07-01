require "gtk2"

class MainWindow < Gtk::Window
  def initialize(yaml)
    super()
    @running = false
    draw_screen
    connect_events
  end

  def draw_screen
    modify_bg Gtk::STATE_NORMAL, Gdk::Color.new(0,0,0)
    hbox = Gtk::HBox.new
    hbox.add @start_pause = Gtk::Button.new('Start')
    hbox.add @reset = Gtk::Button.new('Reset')
    vbox = Gtk::VBox.new
    add vbox
    vbox.add hbox
    vbox.add(@clock = Gtk::Label.new)
    @clock.text = '00:00'
    @clock.modify_font Pango::FontDescription.new('Verdana Bold 78')
    @clock.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse('white')
    vbox.add(@label = Gtk::Label.new)
    @clock.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse('white')
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
    @clock.text = '00:00'
  end

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

  def stop_clock
    @start_pause.label = 'Start'
    @timer.stop
  end
  private :stop_clock

  def start_clock
    @start_pause.label = 'Pause'
    start_or_create_clock
    @clock.text = convert_to_hours
    GLib::Timeout.add(500) do
      next unless running?
      @clock.text = convert_to_hours
    end
  end
  private :start_clock

  def start_or_create_clock
    if @timer.nil?
      @timer ||= GLib::Timer.new
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

  mw = MainWindow.new(YAML.load_file(ARGV[0]))
  mw.show_all
  Gtk.main
end
