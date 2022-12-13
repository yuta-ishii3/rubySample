require 'net/http'
require 'uri'
require 'json'
require "google_drive"

class Codic
  @@API_URL = "https://api.codic.jp/v1/engine/translate.json"

  # コンストラクタ
  # CodicAPIのキーで生成 指定がない場合環境変数を参照する
  # 1時間100件までしか翻訳できない
  def initialize(api_key = "gEPI8xgMczmIe9CapBmvTXgiZhScCNXbqr")
    @api_key = api_key || ENV['CODICAPI']
  end

  def sample()
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1jUXw8bpImtGylGy0O7tWdu25L4T0i7AjNUl6SGHcysM/edit#gid=0")

    # "シート1"という名前のワークシートを取得
    ws = sp.worksheet_by_title("シート1")

    array = [];

    for var in 1..ws.num_rows do
     array.push(ws[var,1])
    end

    for i in 0..array.length do
        word = array[i]
      i+=1
      casing = 'c'
      ws[i,3] = translate(word, casing)
    end
    ws.save
    
  end

  private
    # 翻訳する
    # 指定した日本語に基いて、Codicを用いて翻訳した結果を戻す
    def translate(text, casing = '')
      casing = convertCasing(casing)
      result = request(@@API_URL, {:text => text, :casing => casing})
      result[0]["translated_text"] if result.class == Array && result[0].include?("translated_text")
    end

    # casingをAPI用に変換する
    def convertCasing(casing)
      casingList = {
        'c' => 'camel',
        'p' => 'pascal',
        'l' => 'lower underscore',
        'u' => 'upper underscore',
        'h' => 'hyphen',
      }
      new_casing = casingList[casing]
      new_casing ? new_casing : ''
    end
    # HTTPリクエストを送信し、レスポンスJSONを戻す
    def request(url, params = {})
      uri = URI.parse(appendQueryString(url, params))
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Authorization"] = "Bearer #{@api_key}"
      res = https.request(req)
      JSON.parse(res.body)
    end
    # URLにクエリストリングを付与する
    def appendQueryString(url, params = {})
      query_string = params.map {|key, val| "#{key}=#{URI.encode_www_form_component(val)}"}.join("&")
      url += "?#{query_string}" if query_string
      return url
    end
end

codic = Codic.new
codic.sample()
