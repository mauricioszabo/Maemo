require "main_window"

describe MainWindow do
  before do
    @window = MainWindow.new <<-EOF
      00:00: Foo
      00:01:
        text: foo
        color: FF0000
    EOF
    MainWindow.send :attr_accessor, :clock
    MainWindow.send :attr_accessor, :timer
    MainWindow.send :attr_accessor, :start_pause
  end

  it 'should create a new stopwatch label with 00:00' do
    @window.clock.text.should == '00:00'
  end

  it 'should start the clock' do
    @window.clock.text = ''
    GLib::Timeout.should_receive(:add).with(500)
    @window.start_pause_clock
    @window.clock.text.should == '00:00'
    @window.start_pause.label.should == 'Pause'
  end

  it 'should pause the clock' do
    @window.start_pause_clock
    @window.timer.should_receive(:stop).once
    @window.start_pause_clock
    @window.start_pause.label.should == 'Start'
  end

  it 'should reset the clock' do
    @window.clock.text = ''
    @window.should_receive :stop_clock
    @window.reset_clock
    @window.timer.should be_nil
    @window.clock.text.should == '00:00'
  end
end

def mock_widget(widget)
  m = mock
  widget.stub!(:new).and_return(m)
  m.stub! :signal_connect
  m.stub! :add
end
