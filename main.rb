require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'pp'

BS_URL = 'https://system.bookscan.co.jp/'

Settings = YAML::load(IO::read('settings.yml'))

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'

agent.get("#{BS_URL}login.php") do |page|
  login_result = page.form_with() do |login|
    login['email'] = Settings['email']
    login['password'] = Settings['password']
  end
  login_result.submit
end

new_books_url = ''

agent.get("#{BS_URL}history.php") do |page|
  html = Nokogiri::HTML(page.body)
  element_latest = html.css('table.table5 tr td a')[2]
  new_books_url = BS_URL + element_latest.attributes['href'].value
end

books = []

agent.get(new_books_url) do |page|
  html = Nokogiri::HTML(page.body)
  # pp page.body
  html.css('table.table5 tr td a.downloading').each do |el|
    books.push({
      url: BS_URL + el.attributes['href'].value,
      name: el.children[0].text
    })
  end
end

books.each do |book|
  agent.download(book[:url], "books/#{book[:name]}")
end
