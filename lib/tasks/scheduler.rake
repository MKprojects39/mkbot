namespace :scheduler do
    desc "This task is called by the Heroku scheduler add-on"
    task :update_feed => :enviroment do
        require 'line/bot'
        require 'open-uri'
        require 'kconv'
        require 'rexml/document'
        
        client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
        }
        
        url = "https://www.drk7.jp/weather/xml/13.xml"
        xml = open( url ).read.touft8
        doc = REXML::Document.new(xml)
        
        xpath = 'weatherforecast/pref/area[4]/info/rainfallchance/'
        
        per06to12 = doc.elements[xpath + 'period[2]'].text
        per12to18 = doc.elements[xpath + 'period[3]'].text
        per18to24 = doc.elements[xpath + 'period[4]'].text
        weather = doc.elements[xpath + 'info[1]/weather'].text
        maxtemp = doc.elements[xpath + 'info[1]/temperature/range[1]'].text
        mintemp = doc.elements[xpath + 'info[1]/temperature/range[1]'].text
        
        
        
        min_per = 0
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["いい朝だな！",
       "おはよう！",
       "おはめにゃ",
       "おはようございます。",
       "朝です。",
       "おはゆめ",
       "Mです。"].sample
    word2 =
      ["気をつけて行ってこいよ！",
       "",
       "今日も頑張って働こうなｗ(^^)",
       "今日も一日楽しんでいきましょう！",
       "よい１日を"].sample
    word4 =
      ["チーズ","MC","ネギトロ","サイゼ","寿司","ドンキー","いのいち","米","ガパオ","カオマンガイ","まっちゃんハンバーグ","ガスト","爆弾ハンバーグ","ファミチキ","蒙古","肉まん","温野菜","焼肉","ラーメン(猫田)","高級フレンチ","ファッキン",]
    # 降水確率によってメッセージを変更する閾値の設定
    mid_per = 50
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
      word3 = "今日は雨が降りそうだから傘を忘れるな！"
    else
      word3 = "今日は雨が降るかもしれないから家にいましょう！"
    end
    # 発信するメッセージの設定
    push =
      "#{word1}\n#{word3}\n以下、今日の天気予報です。\n天候　#{weather}\n最高気温　 #{maxtemp}°\n最低気温　 #{mintemp}°\n降水確率　#{per12to18}％\n今日のラッキーフードは#{word4}です。\n#{word2}"
    # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end
end

