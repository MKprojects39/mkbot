class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          url  = "https://www.drk7.jp/weather/xml/13.xml"
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[4]/'
          
          min_per = 40
          mid_per = 0
          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(明日|あした).*/
            # info[2]：明日の天気
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
            weather = doc.elements[xpath + 'info[2]/weather'].text
            maxtemp = doc.elements[xpath + 'info[2]/temperature/range[1]'].text
            mintemp = doc.elements[xpath + 'info[2]/temperature/range[2]'].text
            if per06to12.to_i > min_per || per12to18.to_i > min_per || per18to24.to_i > min_per
              push =
                "明日の天気をお伝えします。\n明日は雨が降りそう...\n\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％"
            else
              push =
                "明日の天気をお伝えします。\n明日は雨は降らなそうだぞ！\n\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％"
            end
          when /.*(明後日|あさって).*/
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text
            weather = doc.elements[xpath + 'info[3]/weather'].text
            maxtemp = doc.elements[xpath + 'info[3]/temperature/range[1]'].text
            mintemp = doc.elements[xpath + 'info[3]/temperature/range[2]'].text
            if per06to12.to_i > min_per || per12to18.to_i > min_per || per18to24.to_i > min_per
              push =
                "明後日の天気をお伝えします。\n明後日は雨が降りそう...\n\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％"
            else
              push =
                "明後日の天気をお伝えします。\n明後日は雨は降らなそうだぞ！\n\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％"
            end
          when /.*(ごはん|ご飯|御飯|えさ|エサ|餌).*/
            word5 = ["チーズ","MC","ネギトロ","サイゼ","寿司","ドンキー","いのいち","トリキ","タイ料理","餌抜き！","まっちゃんハンバーグ","ガスト","パスタ","イタリアン","おにぎり","ソーセージ","いつもの","ケンタッキー","爆弾ハンバーグ","ファミチキ","蒙古","油そば","温野菜","焼肉","ラーメン(猫田)","高級フレンチ","ファッキン"].sample
            push = "#{word5}"
            
          when /.*(かわいい|可愛い|みく|みくちゃん|ミク|えむ|エム|かっこいい|M|ありがとう|イケ猫|みゃ|イケネコ|すてき|かわいいね|可愛いね|ありがと|すごい|スゴイ|すき|好き|いいこ|ゆめ|ゆく).*/
            per06to12 = doc.elements[xpath + 'info[1]/rainfallchance/period[2]'].text
            if per06to12.to_i >= mid_per
            word6 =
                ["みゃ",
                "しってる",
                "💛",
                "あり(=^・・^=)",
                "月が綺麗ですね...",
                "日々成長",
                "ゆめ💛"].sample
            push =
              "#{word6}"
            end
          when /.*(使い方|つかいかた).*/
            push = "使い方を説明します。\n\n\n毎朝7時にお天気、気温、降水確率をお知らせします!\n\n「天気、てんき、今日、気温、あ、a」のどれかを送信で今日の天気予報をお知らせします。\n\n「明日、あした」「明後日、あさって」送信でそれぞれの天気予報をお知らせします。\n\n「えさ、ご飯...ex」などごはんを連想させるワードを送信でごはんをお伝えします。\n\n\nその他会話もできるので話しかけてみてください！"
          when /.*(天気|気温|てんき|今日|あ|a).*/
              per06to12 = doc.elements[xpath + 'info[1]/rainfallchance/period[2]'].text
              per12to18 = doc.elements[xpath + 'info[1]/rainfallchance/period[3]'].text
              per18to24 = doc.elements[xpath + 'info[1]/rainfallchance/period[4]'].text
              weather = doc.elements[xpath + 'info[1]/weather'].text
              maxtemp = doc.elements[xpath + 'info[1]/temperature/range[1]'].text
              mintemp = doc.elements[xpath + 'info[1]/temperature/range[2]'].text
            
            if per06to12.to_i > min_per || per12to18.to_i > min_per || per18to24.to_i > min_per
              word7 =
                ["雨だから家にいましょう",
                 "地下に避難",
                 "雨なのでおやすみなさい"].sample
              push =
                "今日の天気？\n今日は雨が降りそうだから傘があった方が安心だよ。\n\n今日の天気予報です。\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％\n\n#{word7}"
            else
              push =
              "こんにちは。\n今日の天気予報です。\n\n・天候: #{weather}\n・最高気温: #{maxtemp}°\n・最低気温: #{mintemp}°\n・降水確率: #{per12to18}％"
            end
             when /.*(aaaaa|bbbbb).*/
                 push = "w"
            else
                word8 =
                ["zzz",
                 "寝てます",
                 "ただいま睡眠中zzz",
                 "静かに",
                 "狩り中",
                 "食事中",
                 "顔洗い中",
                 "シャー",
                 "仕事中です"
                 ].sample
                push =
                  "#{word8}"
               
          end
          # テキスト以外（画像等）のメッセージが送られた場合
        else
          push = "画像やめろｗ"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
        # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end