#!/usr/bin/env ruby
require "json"
require 'nokogiri'
require 'date'
require 'time'
require 'optparse'

def process(label,array,xml)
  array.each do |hash|
    xml.send(label) do
      hash.each do |key,value|
        if value.is_a?(Array)
          process(key,value,xml)
        elsif key == 'wp:comment_content'
          xml.send(key) { xml.cdata(value) }
        elsif /date_gmt/.match(key)
          xml.send(key, DateTime.parse(value).strftime("%Y-%m-%d %H:%M:%S"))
        else
          xml.send(key,value)
        end
      end
    end
  end
end

def duoshuo(json)
  comments = {}
  json['posts'].each do |c|
    comment = {
      'wp:comment_id' => c['post_id'],
      'wp:comment_author' => c['author_name'],
      'wp:comment_author_email' => c['author_email'],
      'wp:comment_author_url' => c['author_url'],
      'wp:comment_author_IP' => c['ip'],
      'wp:comment_date_gmt' => c['created_at'],
      'wp:comment_content' => c['message'],
      'wp:comment_approved' => 1,
      'wp:comment_parent' => ( c['parents'] ? c['parents'][0].to_i : 0 )
    }
    comments[c['thread_id']] = [] unless comments[c['thread_id']].is_a?(Array)
    comments[c['thread_id']] << comment
  end
  data = []
  comments.each do |id, comms|
    p = json['threads'].select { |h| h['thread_id'].to_i == id }
    article = {
      'title' => p[0]['title'],
      'link' => p[0]['url'],
      'dsq:thread_identifier' => p[0]['thread_key'],
      'wp:post_date_gmt' => p[0]['created_at'],
      'wp:comment_status' => 'open',
      'wp:comment' => comms
    }
    data << article
  end
  data
end

def changyan(json)
  data = []
  json['comments'].each do |c|
    comment = {
      'wp:comment_id' => c['id'],
      'wp:comment_author' => c['nickname'],
      'wp:comment_date_gmt' => c['ctime'],
      'wp:comment_content' => c['content'],
      'wp:comment_approved' => 1,
      'wp:comment_parent' => ( c['replyId'] ? c['replyId'] : 0 )
    }
    article = {
      'title' => c['topicTitle'],
      'link' => c['topicUrl'],
      'dsq:thread_identifier' => c['topicSourceId'],
      'wp:comment_status' => 'open'
    }
    article['wp:comment'] = [] unless article['wp:comment'].is_a?(Array)
    article['wp:comment'] << comment
    data << article
  end
  data
end

def build(arr)
  Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.send('rss', 'version': '2.0', 'xmlns:content': 'http://purl.org/rss/1.0/modules/content/', 'xmlns:dsq': 'http://www.disqus.com/', 'xmlns:dc': 'http://purl.org/dc/elements/1.1/', 'xmlns:wp': 'http://wordpress.org/export/1.0/') do
      xml.channel do
        process('item',arr,xml)
      end
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: migrate.rb [options]"
  opts.on('-f json_file', '--from json_file', 'Specify json file to convert from') { |v| options[:from] = v }
  opts.on('-t xml_file', '--to xml_file', 'Specify xml file to convert to') { |v| options[:to] = v }
  opts.on('-h', '--help', 'Display help') do
    puts opts
    exit
  end
end.parse!

file = File.new(options[:from], "r")
json = JSON.parse(file.read)
if json['generator'] == 'duoshuo'
  builder = build(duoshuo(json))
else
  builder = build(changyan(json))
end
File.open(options[:to], "w+") { |f| f.write(builder.to_xml) }
