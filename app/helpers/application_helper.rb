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
    date ? date.localtime.strftime("%Y-%m-%d") : "yyyy-mm-dd"
  end

  def format_short_time(time)
    time ? time.localtime.strftime("%I:%M %p") : "--:--"
  end

  def format_long_time(time)
    time ? time.localtime.strftime("%I:%M:%S %p %Y-%m-%d") : "--:--"
  end

end
