# -*- encoding: utf-8 -*-

require 'jma/receview/generation'
require 'kconv'

class ReceView_API
  require 'uri'
  require 'net/http'
  require 'rexml/document'

  CONTENT_TYPE = "application/xml"

  def initialize(server="http://localhost:8000", user="ormaster", pass="ormaster")
    # Rubyのバージョンが1.9.2以前の場合はnet/httpsを読み込む
    require 'net/https' if RUBY_VERSION <= "1.9.2"

    Net::HTTP.version_1_2
    @uri = URI.parse(server)
    @user = user
    @pass = pass
    @http = Net::HTTP.new(@uri.host, @uri.port, nil)
    @http.open_timeout = 10
    @http.read_timeout = 10
    if @uri.scheme == "https"
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end

  def setting_client_auth(ca_file, cert_file, pkey_file, pass_phrase)
    @http.ca_file = ca_file
    if /mingw|cygwin|mswin/ =~ RUBY_PLATFORM.downcase
      cert_file_content = File.new(cert_file.tosjis).read
      pkey_file_content = File.new(pkey_file.tosjis).read
    else
      cert_file_content = File.new(cert_file).read
      pkey_file_content = File.new(pkey_file).read
    end
    @http.cert = OpenSSL::X509::Certificate.new(cert_file_content)
    @http.key = OpenSSL::PKey::RSA.new(pkey_file_content, pass_phrase)
  end

  def exec_api(body, url)
    req = Net::HTTP::Post.new(url)

    req.content_length = body.size
    req.content_type = CONTENT_TYPE
    req.body = body
    req.basic_auth(@user, @pass)

    res = @http.start { |http| http.request(req) }
    return (res.code =~ /2\d{2}/)? REXML::Document.new(res.body) : res
  end

  def create_request_insprogetv2(provider="")
    body = <<-EOF
      <data>
        <insprogetreq type="record">
          <InsuranceProvider_Number type="string">#{provider}</InsuranceProvider_Number>
        </insprogetreq>
      </data>
    EOF
  end

  def parse_response_insprogetv2(res)
    unless REXML::Document === res
      return {
        "hknjanum"  => { :value => "" },
        "hknjaname" => { :value => "" }
      }
    end
    providers = res.elements['//TInsuranceProvider_Information']
    if providers
      hknjainf = {
        "hknjanum"  => {
          :value => providers.elements['*/InsuranceProvider_Number'].text
        },
        "hknjaname" => {
          :value => providers.elements['*/InsuranceProvider_WholeName'].text
        }
      }
    else
      hknjainf = {
        "hknjanum"  => { :value => "" },
        "hknjaname" => { :value => "" },
        "result"    => { :value => res.elements['//Api_Result'].text },
        "message"   => { :value => res.elements['//Api_Result_Message'].text }
      }
    end
    hknjainf.each { |_,hash| hash[:value] = hash[:value].toeuc }
  end
end

if __FILE__ == $0
  @api = ReceView_API.new(*ARGV)
  req = @api.create_request_insprogetv2("320010")
  res = @api.exec_api(req, "/api01rv2/insprogetv2")
  hknjainf = @api.parse_response_insprogetv2(res)

  hknjainf.each do |_,hash|
    hash[:value] = hash[:value].toutf8
  end
  p hknjainf
end
