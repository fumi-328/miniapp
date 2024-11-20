require 'line/bot'

class LineBotController < ApplicationController
  protect_from_forgery except: :callback

  # LINE Webhook エンドポイント
  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    unless client.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = client.parse_events_from(body)

    events.each do |event|
      if event.is_a?(Line::Bot::Event::Message) && event.type == Line::Bot::Event::MessageType::Text
        reply_with_qiita_article(event)
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def reply_with_qiita_article(event)
    response = HTTParty.get('https://qiita.com/api/v2/items', query: { per_page: 1, page: rand(1..100) })
    article = response.parsed_response.first

    message = {
      type: 'text',
      text: "おすすめ記事:\n#{article['title']}\n#{article['url']}"
    }
    client.reply_message(event['replyToken'], message)
  end
end
