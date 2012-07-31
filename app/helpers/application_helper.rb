module ApplicationHelper
  
  def email_logo
    '/public/images/logo.png'
  end

  def flash_message
    flashes = ""
    alert_classes = {
      :alert => "error", :error => "error",
      :notice => "success", :warning => "block",
      :info => "info"
    }
    flash.map do |name, msg|
      str = %Q{
        <div class='alert alert-#{alert_classes[name.to_sym]}'>
           <button class='close' data-dismiss='alert'>&times;</button>
           #{msg}
        </div>
      }
      flashes << str.html_safe
      flash.delete(name.to_sym)
    end
    flashes.html_safe
  end

  def set_active(condition = false)
    'active' if condition
  end

  def format_date(date)
    return 'yyyy-mm-dd' unless date
    date = date.is_a?(Time) ? User.of_localtime(date).to_date : date
    I18n.l(date, :format => :default)
  end

  def format_long_time(time)
    time ? I18n.l(User.of_localtime(time), :format => :long_with_date_default) : "--:--"
  end

  def format_short_time_with_sec(time)
    time ? I18n.l(User.of_localtime(time), :format => :short_with_sec) : "--:--"
  end

  def format_time_in_long_with_date(time)
    time ? I18n.l(User.of_localtime(time), :format => :long_with_date) : "mm-dd-yyyy --:--"
  end
  
  def format_long_date_with_time(time)
    time ? I18n.l(User.of_localtime(time), :format => :long_date_with_time) : "mmm dd, yyyy --:--"
  end
  
  def vars_to_js
    str = ""
    unless @js_params.blank?
      str << %Q(
        <script>
        window.rb = {};
      )
      @js_params.each do |name, val|
        var_name = name.to_s.camelize.sub(/\b\w/) { $&.downcase }
        str << "rb.#{var_name} = #{val.to_json};"
      end
    str << "</script>"
    end
    str.html_safe
  end
end
