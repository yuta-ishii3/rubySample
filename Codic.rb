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

  def camerCase(sheetUrl)
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url(sheetUrl)

    # "シート1"という名前のワークシートを取得
    ws1 = sp.worksheet_by_title("DBレイアウト")
    ws2 = sp.worksheet_by_title("翻訳")

    array = [];

    for var in 8..ws1.num_rows do
      if ws1[var,2].blank? then
        break
      end
     array.push(ws1[var,2])
    end

    for i in 0..array.length do
      word = array[i]
      i+=1
      casing = 'c'
      if ws2[i,1].blank? then
        ws2[i,1] = translate(word, casing)
      end
    end
    ws1.save
    ws2.save
  end

  def createSetter(sheetUrl)
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url(sheetUrl)

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
      end
    end
    ws3.save
    ws4.save
    puts "createSetter"
  end

  def createData(sheetUrl)
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url(sheetUrl)

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
      ws6[j,1] = "/**#{aaa}*/pivate #{kata} #{hensu};"
    end
    puts "createData"
    ws5.save
    ws6.save
  end

  def createTable(sheetUrl)
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url(sheetUrl)

    # "シート1"という名前のワークシートを取得
    wsheet1 = sp.worksheet_by_title("DBレイアウト")
    wsheet2 = sp.worksheet_by_title("TABLE")

    array_koumokuId = [];
    array_type = [];
    array_keta1 = [];
    array_keta2 = [];
    array_koumokuName = []; 

    for var in 8..wsheet1.num_rows do
      if wsheet1[var,2].blank? then
        break
      end
      array_koumokuId.push(wsheet1[var,3])
      array_type.push(wsheet1[var,4])
      array_keta1.push(wsheet1[var,5])
      array_keta2.push(wsheet1[var,6])
      array_koumokuName.push(wsheet1[var,2])
    end

    for i in 0..array_koumokuName.length do
      if i == 0 then
        aaa = wsheet1[6,1]
        wsheet2[1,1]="CREATE TABLE [ IF NOT EXISTS ] #{aaa}( "
      end
      if array_type[i] == "VARCHAR2" then
        array_type[i] = "VARCHAR"
      elsif array_type[i] == "DATE" then
        array_type[i] = "TIMESTAMP WITH TIME ZONE(0)"
      elsif array_type[i] == "NUMBER" then
        array_type[i] = "NUMERIC"
      end
      j=i+2
      wsheet2[j,1] = "#{array_koumokuId[i]} #{array_type[i]}"
      if array_keta1[i].blank? then
        wsheet2[j,1] = wsheet2[j,1]+","
      elsif array_keta2[i].blank? then
        wsheet2[j,1] = wsheet2[j,1]+"(#{array_keta1[i]}),"
      elsif true then
        keta1 = array_keta1[i].to_i
        keta2 = array_keta2[i].to_i
        keta = keta1 + keta2
        wsheet2[j,1] = wsheet2[j,1]+"(#{keta},#{array_keta2[i]}),"
      end
      i+=1
      if i == array_koumokuName.length then
        wsheet2[j,1].slice!(wsheet2[j,1].length-1)
        wsheet2[j,1] = wsheet2[j,1] +");"
      end
    end
    wsheet1.save
    wsheet2.save
  end

  
  def createComment(sheetUrl)
    # config.jsonを読み込んでセッションを確立
    session = GoogleDrive::Session.from_config("config.json")

    # スプレッドシートをURLで取得
    sp = session.spreadsheet_by_url(sheetUrl)

    # "シート1"という名前のワークシートを取得
    wsheet3 = sp.worksheet_by_title("DBレイアウト")
    wsheet4 = sp.worksheet_by_title("TABLE")

    koumokuName = [];
    koumokuId = [];

    for var in 8..wsheet3.num_rows do
     koumokuName.push(wsheet3[var,2])
     koumokuId.push(wsheet3[var,3])
     if wsheet3[var,2].blank? then
      break
     end
    end

    for i in 0..koumokuName.length-1 do
      if i == 0 then
        wsheet4[1,5] = "COMMENT ON TABLE #{wsheet3[6,1]} IS '#{wsheet3[6,3]}';"
        next
      end
      j=i+1
      k=i-1
      wsheet4[j,5] = "COMMENT ON COLUMN #{wsheet3[6,1]}.#{koumokuId[k]} IS '#{koumokuName[k]}';"
    end
    wsheet4.save
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
puts "スプレットシートのURLを入力"
input = gets
codic.camerCase(input.chomp)
codic.createData(input.chomp)
codic.createTable(input.chomp)
codic.createComment(input.chomp)





