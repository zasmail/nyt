require 'byebug'
require 'open-uri'
require 'pp'
require 'nokogiri'
require 'progress_bar'
require 'json'
require 'algoliasearch'
require 'faker'
require 'social_shares'
require 'date'
require 'saxerator'
require 'csv'

@books = {}
def get_book_list(list, date)
  uri = URI("https://api.nytimes.com/svc/books/v3/lists.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  uri.query = URI.encode_www_form({
    "api-key" => "e633351decde48cc87560dada72b6384",
    "list" => "combined-print-and-e-book-fiction"
  })
  request = Net::HTTP::Get.new(uri.request_uri)
  result = JSON.parse(http.request(request).body)
  if !result['results'].nil?
    result['results'].each do |book|
      book_details =  book['book_details'].first
      @books[list['list_name']][:books] << book
    end
  end
end

def handle_list(list)
  @books[list['list_name']] = {
    list_name_encoded: list['list_name_encoded'],
    newest_published_date: list['newest_published_date'],
    oldest_published_date: list['oldest_published_date'],
    books: []
  }
  start_date = Date.parse(list['newest_published_date'])
  end_date = Date.parse(list['oldest_published_date'])
  index_date = start_date
  offset = list['updated'] == 'WEEKLY' ? 7 : 30
  bar = ProgressBar.new(((index_date - end_date)/offset).to_i)
  while index_date >= end_date do
    bar.increment!
    get_book_list(list, index_date)
    index_date = index_date - offset
  end
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/names.json")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
uri.query = URI.encode_www_form({
  "api-key" => "e633351decde48cc87560dada72b6384"
})
request = Net::HTTP::Get.new(uri.request_uri)
@result = JSON.parse(http.request(request).body)
lists = @result['results']
byebug
bar = ProgressBar.new(lists.length)
lists.each do |list|
  bar.increment!
  pp list['list_name']
  handle_list(list)
end

File.open("books.json","w") do |f|
  f.write(@books.to_json)
end

pp "hi"
