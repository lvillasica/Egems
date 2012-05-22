module ApplicationHelper
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

  def email_logo
    '/public/images/logo.png'
  end
end
