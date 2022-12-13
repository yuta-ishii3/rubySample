require 'net/http'
require 'uri'
require 'json'
require "google_drive"
require 'active_support'

class Codic
  @@API_URL = "https://api.codic.jp/v1/engine/translate.json"

  # コンストラクタ
  # CodicAPIのキーで生成 指定がない場合環境変数を参照する
  # 1時間100件までしか翻訳できない
  def initialize(api_key = "BtGkE1VzDU7hHb1lH5BFC2VoAZ7ghLstyx")
    @api_key = api_key || ENV['CODICAPI']
  end

  def camerCase()
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1jUXw8bpImtGylGy0O7tWdu25L4T0i7AjNUl6SGHcysM/edit#gid=1388734309")

    # "シート1"という名前のワークシートを取得
    ws1 = sp.worksheet_by_title("DBレイアウト")
    ws2 = sp.worksheet_by_title("翻訳")

    array = [];

    for var in 8..ws1.num_rows do
      puts var
      if ws1[var,2].blank? then
        break
      end
     array.push(ws1[var,2])
    end

    for i in 7..array.length do
      word = array[i]
      i+=1
      casing = 'c'
      ws2[i,1] = translate(word, casing)
    end
    ws1.save
    ws2.save
  end

  def createSetter()
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1jUXw8bpImtGylGy0O7tWdu25L4T0i7AjNUl6SGHcysM/edit#gid=1388734309")

    # "シート1"という名前のワークシートを取得
    ws3 = sp.worksheet_by_title("翻訳")
    ws4 = sp.worksheet_by_title("Setter")

    array = [];

    for var in 8..ws3.num_rows do
     array.push(ws3[var,1])
    end

    for i in 0..array.length do
      word = array[i]
      if !word.nil? then
        aaa = word.slice(0,1)
        word.slice!(0)
        bbb = aaa.upcase + word
        i+=1
        ws4[i,1] = "set#{bbb}();"
        ws3.save
        ws4.save
      end
    end
    puts "createSetter"
  end

  def createData()
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1jUXw8bpImtGylGy0O7tWdu25L4T0i7AjNUl6SGHcysM/edit#gid=1388734309")

    # "シート1"という名前のワークシートを取得
    ws5 = sp.worksheet_by_title("DBレイアウト")
    ws6 = sp.worksheet_by_title("DATA")
    ws7 = sp.worksheet_by_title("翻訳")

    array = [];

    for var in 8..ws5.num_rows do
     array.push(ws5[var,2])
    end

    for i in 8..array.length do
      i+=1
      j=i-8
      aaa = ws5[i,2]
      hensu = ws7[j,1]
      kata = ws5[i,4]
      if kata == "VARCHAR2" then
        kata = "String"
      elsif kata == "DATE" then
        kata = "OffsetDateTime"
      elsif kata == "NUMBER" then
        kata = "BigDecimal"
      end
      ws6[i,1] = "/**#{aaa}*/pivate #{kata} #{hensu};"
      ws5.save
      ws6.save
    end
    puts "createData"

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
codic.camerCase()
codic.createData()
codic.createSetter()


