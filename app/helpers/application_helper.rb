module ApplicationHelper
  def flash_message
    flashes = ""
    flash.map do |name, msg|
      str = %Q{
        <div class="alert alert-error" id='flash_#{name}'>
           <button class="close" data-dismiss="alert">x</button>
        </div>
      }
      flashes<< str.html_safe if name.eql?(:alert)
    end
    flashes
  end
end
