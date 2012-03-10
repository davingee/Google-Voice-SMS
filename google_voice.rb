require 'net/http'
require 'net/https'
require 'uri'
require 'mechanize'
require 'nokogiri'

class GoogleVoiceText
  # Your google username, password, the number to send sms, and what you want to send
  
  # PLEASE FILL OUT
  # constants for demo only
  USERNAME = "" # user@gmail.com
  PASSWORD = "" # password
  NUMBER = ""   # 123-555-1212
  TEXT = "So whats that about 'Your in the jungle baby'"

  def get_mech
    Mechanize.html_parser = Nokogiri::HTML
    Mechanize.new do |the_agent|
      # the_agent.log = Logger.new(STDERR) 
      the_agent.redirection_limit = 20
      the_agent.user_agent_alias = 'Mac FireFox'
      the_agent.redirect_ok = true
    end
  end

  # little code needed to send sms via google voice...
  def google_voice_token(refresh=false)
    # refresh goes and gets a new google token for the user if the text fails because i am not sure when it expires.
    unless refresh
      "s8Bz8KbbisoebeQMM7autDWOp/4="
      # this has not expired in 2 months. if new user it will have to get a new one
    else
      # token needed to send text if old one does not work(if live store in db for each user)
      agent = get_mech
      url = "https://accounts.google.com/ServiceLogin?service=grandcentral"
      page = agent.get(url)
      form = page.forms[0]
      form.Email = USERNAME
      form.Passwd = PASSWORD
      page = form.submit
      page = agent.get("https://www.google.com/voice#inbox")
      form = page.forms.first
      form._rnr_se.to_s
    end
  end

  def send_sms_via_google_voice(number, text, refresh_token = false)
    login_response = ""
    url = URI.parse('https://www.google.com/accounts/ClientLogin')
    login_request = Net::HTTP::Post.new(url.path)
    login_request.form_data = {'accountType' => 'GOOGLE', 'Email' => USERNAME, 'Passwd' => PASSWORD, 'service' => 'grandcentral', 'source' => 'scoran.com)'}
    login_connection = Net::HTTP.new(url.host, url.port)
    login_connection.use_ssl = true
    login_connection.start do |http| 
      login_response = http.request(login_request)
    end
    url = URI.parse('https://www.google.com/voice/sms/send/')
    google_auth = login_response.body.match("Auth\=(.*)")[1]
    request = Net::HTTP::Post.new(url.path, { 'Content-type' => "application/x-www-form-urlencoded", 'Authorization' => "GoogleLogin auth=#{google_auth}" })
    # We're sending the auth token back to google
    request.form_data = {'id' => "", 'phoneNumber' => number, 'text' => text, '_rnr_se' => google_voice_token(refresh_token)}
    connection = Net::HTTP.new(url.host, url.port)
    connection.use_ssl = true
    response = ""
    connection.start do |http|
      response = http.request(request)
    end
    response.code == "200"
  end

end

google_text = GoogleVoiceText.new
succeeded = google_text.send_sms_via_google_voice(GoogleVoiceText::NUMBER, GoogleVoiceText::TEXT)
unless succeeded
  # Try again with a refreshed token
  succeeded = google_text.send_sms_via_google_voice(GoogleVoiceText::NUMBER, GoogleVoiceText::TEXT, true)
end
if succeeded
  puts("msg sent")
else
  puts("msg failed")
end