#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8

require 'twitter'
require 'cgi'

class EigoTensaku
  @@since_id_file_path = 'tmp/since_id.txt'
  attr_accessor :client, :corrector
  attr_accessor :consumer_key, :consumer_secret, :access_token, :access_token_secret

  def initialize(corrector,
                 consumer_key,
                 consumer_secret,
                 access_token,
                 access_token_secret)
    @corrector = corrector
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret
    @access_token = access_token
    @access_token_secret = access_token_secret

    # Twitterクライアントを初期化
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = @consumer_key
      config.consumer_secret = @consumer_secret
      config.access_token = @access_token
      config.access_token_secret = @access_token_secret
    end

    # copied from gems/twitter-5.5.1/lib/twitter/rest/client.rb
    @client.middleware = Faraday::RackBuilder.new do |builder|
      # Convert file uploads to Faraday::UploadIO objects
      builder.use Twitter::REST::Request::MultipartWithFile
      # Checks for files in the payload
      builder.use Faraday::Request::Multipart
      # Convert request params to "www-form-urlencoded"
      builder.use Faraday::Request::UrlEncoded
      # Handle error responses
      builder.use Twitter::REST::Response::RaiseError
      # Parse JSON response bodies
      builder.use Twitter::REST::Response::ParseJson
      # Set Faraday's HTTP adapter
      builder.adapter Faraday.default_adapter
    end
  end

  # 前回実行時に処理した最後の twitter id をファイルから取得
  def get_since_id
    File.open(@@since_id_file_path, 'r') {|f|
      f.read.to_i
    }
  end

  def update_since_id(since_id)
    File.open(@@since_id_file_path, 'wb') {|f|
      f.puts(since_id)
    }
  end

  # テキストから @xxx #xxx uri "RT" "QT" などを削除
  def clean_text(text)
    puts "before: #{text}"
    text = text
      .gsub(/@[\w_]+:?/, '')
      .gsub(/#[\w_]+/, '')
      .gsub(/\bhttps?:\/\/\S+/, '')
      .gsub(/\b(RT|QT)\b/, '')
      .gsub(/\s{2,}/, ' ')
      .strip
    text = CGI.unescapeHTML text
    puts "after:  #{text}"
    text
  end

  def tweet(text)
    begin
      @client.update(text)
    rescue Exception => e
      print "!!! ERROR !!! #{e.class}"
    end
  end

  # 添削メッセージをツイートに適した形にまとめて返す
  def organize_messages(error_messages, screen_name)
    error_messages.map do |message|
      puts ">> #{message}"
      "#{screen_name} #{message}".slice(0, 140)
    end
  end

  def process_tweet(tweet)
    #puts "#{tweet.id}: #{tweet.created_at}: @#{tweet.user.screen_name}: #{tweet.text}"
    # ツイート本文から余計なものを取り除いて成形
    text = clean_text(tweet.text)
    if text
      # 英文添削＆お返事作成
      error_messages = @corrector.correct(text)
      #error_messages.each {|e| puts "  #{e['category']}: #{e['locqualityissuetype']}: #{e['msg']} (x:#{e['fromx']}-#{e['tox']}, y:#{e['fromy']}-#{e['toy']}) replacement: #{e['replacements']}" }
      if error_messages.empty?
        # no errors, good job ;)
        #self.tweet("@#{screen_name} good job ;)")
      else
        # 添削結果をツイート
        screen_name = tweet.user.screen_name
        reply_messages = organize_messages(error_messages, screen_name)
        reply_messages.each do |message|
          self.tweet(message)
        end
      end
    end
  end

  def search_tweets(phrase, since_id)
    tweets = @client.search(phrase, result_type: :recent, since_id: since_id, lang: :en)
    if tweets.count > 0 and block_given?
      # 見つかったツイートを処理
      count = 5 # !!! DEBUG !!!
      tweets.each do |tweet|
        break if tweet.id <= since_id
        if tweet.is_a? Twitter::Tweet
          # process the tweet with the given block
          yield tweet
        end
        count -= 1 # !!! DEBUG !!!
        break if count <= 0 # !!! DEBUG !!!
      end
    end
    tweets
  end

  def run(search_phrase)
    # 前回最後に処理したツイートidを取得
    since_id = get_since_id

    # twitter検索してヒットしたツイートを処理
    tweets = search_tweets(search_phrase, since_id) do |tweet|
      process_tweet(tweet)
    end

    # 最後に処理したツイートidを記録
    new_since_id = tweets.first.id
    puts new_since_id
    update_since_id(new_since_id)
  end
end
