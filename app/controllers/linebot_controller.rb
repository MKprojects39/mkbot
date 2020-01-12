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
          
          min_per = 50
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
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明日の天気を教えてやる。\n明日は雨が降りそう...\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n"
            else
              push =
                "明日の天気を教えてやる。\n明日雨は降らなそうだぞ！\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n"
            end
          when /.*(明後日|あさって).*/
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text
            weather = doc.elements[xpath + 'info[3]/weather'].text
            maxtemp = doc.elements[xpath + 'info[3]/temperature/range[1]'].text
            mintemp = doc.elements[xpath + 'info[3]/temperature/range[2]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
                "明後日の天気を教えてやる。\n明日は雨が降りそう...\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n"
            else
              push =
                "明後日の天気を教えてやる。\n明日雨は降らなそうだぞ！\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n"
            end
          when /.*(ごはん|ご飯|御飯|えさ|エサ|餌|).*/
            word = ["チーズ","MC","ネギトロ","サイゼ","寿司","ドンキー","いのいち","米","ガパオ","カオマンガイ","まっちゃんハンバーグ","ガスト","爆弾ハンバーグ","ファミチキ","蒙古","肉まん","温野菜","焼肉","ラーメン(猫田)","高級フレンチ","ファッキン",]
            push = "#{word}"
          when /.*(かわいい|可愛い|かっこいい|きれい|綺麗|イケ猫|素敵|イケネコ|すてき|かわいいね|可愛いね|ありがと|すごい|スゴイ|すき|好き|頑張|がんば|ガンバ).*/
            word=
                ["みゃ",
                "しってる",
                "💛",
                "あり(=^・・^=)",
                "月が綺麗ですね..."].sample
            push =
              "#{word}"
          when /.*(みく|みくちゃん|ミク|えむ|エム|天気|気温|М|m|今日|あ|a|).*/
              per06to12 = doc.elements[xpath + 'info[1]/rainfallchance/period[2]'].text
              per12to18 = doc.elements[xpath + 'info[1]/rainfallchance/period[3]'].text
              per18to24 = doc.elements[xpath + 'info[1]/rainfallchance/period[4]'].text
              weather = doc.elements[xpath + 'info[1]/weather'].text
              maxtemp = doc.elements[xpath + 'info[1]/temperature/range[1]'].text
              mintemp = doc.elements[xpath + 'info[1]/temperature/range[2]'].text
            push =
              "こんにちは。\n今日の天気予報です。\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％"
          else
            per06to12 = doc.elements[xpath + 'info[1]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[1]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[1]/rainfallchance/period[4]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              word =
                ["雨だから家にいましょう",
                 "地下に避難",
                 "雨なのでおやすみなさい"].sample
              push =
                "今日の天気？\n今日は雨が降りそうだから傘があった方が安心だよ。\n今日の天気予報です。\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n#{word}"
            else
              word =
                ["zzz",
                 "寝てます",
                 "ただいま睡眠中zzz",
                 "静かに",
                 "狩り中",
                 "食事中",
                 "顔洗い中"].sample
              push =
                "#{word}"
            end
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