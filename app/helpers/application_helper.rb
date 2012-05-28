module ApplicationHelper

  def email_logo
    '/public/images/logo.png'
  end

  def flash_message
    flashes = ""
    flash.map do |name, msg|
      str = %Q{
        <div class='alert alert-error' id='flash_#{name}'>
           #{msg}
           <button class='close' data-dismiss='alert'>&times;</button>
        </div>
      }
      flashes << str.html_safe if name.eql?(:alert)
    end
    flashes.html_safe
  end


  def format_date(date)
    return 'yyyy-mm-dd' unless date
    date = date.is_a?(Time) ? date.to_date : date
    I18n.l(date, :format => :default)
  end

  def format_long_time(time)
    time ? I18n.l(User.of_localtime(time), :format => :short) : "--:--"
  end

  def format_short_time_with_sec(time)
    time ? I18n.l(User.of_localtime(time), :format => :short_with_sec) : "--:--"
  end

  def format_time_in_long_with_date(time)
    time ? I18n.l(User.of_localtime(time), :format => :long_with_date) : "mm-dd-yyyy --:--"
  end
end
