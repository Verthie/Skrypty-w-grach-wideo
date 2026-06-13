require "nokogiri"
require "net/http"
require "uri"
require "json"

# konfiguracja
BASE_URL = "https://www.morele.net"
CATEGORY_PATH = "/kategoria/fotele-gamingowe-747"
MAX_PAGES = 1 # ile stron kategorii pobrać (0 = wszystkie)
DELAY_SEC = 1.5 # opóźnienie między żądaniami
OUTPUT_FILE_3 = "produkty3_0.json"  # wyniki kategorii
OUTPUT_FILE_35 = "produkty3_5.json" # wyniki wyszukiwania
OUTPUT_FILE_4 = "produkty4_0.json"  # szczegółowe dane produktów

HEADERS = {
  "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
  "AppleWebKit/537.36 (KHTML, like Gecko) " \
  "Chrome/124.0.0.0 Safari/537.36",
  "Accept-Language" => "pl-PL,pl;q=0.9,en;q=0.8",
  "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
}.freeze

# pobieranie strony z obsługą przekierowań
def fetch(url, max_redirects: 5)
  uri = URI.parse(url)
  tried = 0

  loop do
    raise "Zbyt wiele przekierowań" if tried >= max_redirects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
    response = http.request(request)

    case response.code.to_i
    when 200
      return response.body
    when 301, 302, 303, 307, 308
      location = response["Location"]
      uri = location.start_with?("http") ? URI.parse(location) : URI.parse("#{BASE_URL}#{location}")
      tried += 1
    else
      raise "HTTP #{response.code} dla #{url}"
    end
  end
end

# parsowanie pojedynczej strony kategorii => zwraca { title, price }
def parse_product_list(html)
  doc = Nokogiri::HTML(html)
  products = []

  # produkty danej kategorii
  items = doc.css(".cat-product, .c-product")

  items.each do |item|
    # tytuł produktu
    title_node = item.at_css(".cat-product-name a, .c-product__name a, a.cat-product-name")
    title = title_node&.text&.strip

    # cena
    price_el = item.at_css("[data-price]")
    price_text = price_el&.[]("data-price")
    price_text = "#{price_text} zł" if price_text

    if price_text.nil? || price_text.empty?
      price_text = item.at_css(".price-new")&.text&.strip
    end

    next if title.nil? || title.empty?

    products << {
      title: title,
      price: price_text || "brak ceny",
    }
  end

  products
end

# sprawdza, czy istnieje kolejna strona paginacji
def next_page_path(html, current_page)
  doc = Nokogiri::HTML(html)
  
  next_num = current_page + 1
  link = doc.at_css("a.pagination__page[href*='/#{next_num}/'], " \
  "a[aria-label='Następna strona'], " \
  ".pagination .next a")
  link&.[]("href")
end

def crawl_category
  all_products = []
  page = 1
  path = "#{CATEGORY_PATH}/1/"

  loop do
    url = "#{BASE_URL}#{path}"
    puts "[strona #{page}] Pobieranie: #{url}"

    begin
      html = fetch(url)
      products = parse_product_list(html)
      puts "znaleziono #{products.size} produktów"
      all_products.concat(products)
    rescue => e
      puts "BŁĄD: #{e.message} – pomijam stronę"
      break
    end

    break if MAX_PAGES && page >= MAX_PAGES

    next_path = next_page_path(html, page)
    break unless next_path

    path = next_path.start_with?("http") ? URI.parse(next_path).path : next_path
    page += 1
    sleep(DELAY_SEC)
  end

  all_products
end

def crawl_search(keyword, max_pages: MAX_PAGES)
  all_products = []
  page = 1
  encoded = URI.encode_www_form_component(keyword)
  url = "#{BASE_URL}/wyszukiwarka/?q=#{encoded}&p=1"
 
  loop do
    puts "[szukaj: \"#{keyword}\" | strona #{page}] #{url}"
 
    begin
      html = fetch(url)
      products = parse_product_list(html)
      puts "#{products.size} produktów"
      all_products.concat(products)
    rescue => e
      puts "BŁĄD: #{e.message} – pomijam stronę"
      break
    end
 
    break if max_pages && page >= max_pages
 
    next_url = next_page_path(html, page)
    break unless next_url
 
    url = next_url.start_with?("http") ? next_url : "#{BASE_URL}#{next_url}"
    page += 1
    sleep(DELAY_SEC)
  end
 
  # oznacz skąd pochodzi produkt
  all_products.each { |p| p[:keyword] = "#{keyword}" }
  all_products
end

def parse_product_urls(html)
  doc = Nokogiri::HTML(html)
  doc.css(".cat-product, .c-product").filter_map do |item|
    node = item.at_css(".cat-product-name a, .c-product__name a, a.cat-product-name")
    next unless node&.text&.strip&.length&.positive?
    href = node["href"]
    next unless href
    href.start_with?("http") ? href : "#{BASE_URL}#{href}"
  end
end

def parse_product_details(html)
  doc = Nokogiri::HTML(html)
 
  # morele osadza obiekt Product w <script type="application/ld+json">
  json_ld = {}
  doc.css('script[type="application/ld+json"]').each do |script|
    begin
      data = JSON.parse(script.text)
      json_ld = data if data["@type"] == "Product"
    rescue JSON::ParserError
    end
  end
 
  # dane z JSON-LD
  brand = json_ld.dig("brand", "name")
  rating = json_ld.dig("aggregateRating", "ratingValue")
  review_count = json_ld.dig("aggregateRating", "reviewCount")

  {
    brand: brand,
    rating: rating,
    review_count: review_count,
  }
end

def crawl_category_urls
  all_urls = []
  page = 1
  path = "#{CATEGORY_PATH}/1/"
 
  loop do
    url = "#{BASE_URL}#{path}"
    puts "[URL-e | strona #{page}] Pobieranie: #{url}"
 
    begin
      html = fetch(url)
      urls = parse_product_urls(html)
      puts "znaleziono #{urls.size} URL-i"
      all_urls.concat(urls)
    rescue => e
      puts "BŁĄD: #{e.message} – pomijam stronę"
      break
    end
 
    break if MAX_PAGES && page >= MAX_PAGES
 
    next_path = next_page_path(html, page)
    break unless next_path
 
    path = next_path.start_with?("http") ? URI.parse(next_path).path : next_path
    page += 1
    sleep(DELAY_SEC)
  end
 
  all_urls
end


def enrich_with_details(products, urls)
  enriched = []
  total = products.size
 
  products.each_with_index do |prod, idx|
    url = urls[idx]
 
    if url.nil? || url.empty?
      puts "[#{idx + 1}/#{total}] brak URL – pomijam"
      enriched << prod
      next
    end
 
    puts "[#{idx + 1}/#{total}] #{prod[:title]&.slice(0, 55)}"
 
    begin
      html = fetch(url)
      details = parse_product_details(html)
      enriched << prod.merge(details)
    rescue => e
      puts "BŁĄD: #{e.message}"
      enriched << prod
    end
 
    sleep(DELAY_SEC)
  end
 
  enriched
end



# main

# 3.0 produkty z kategorii
puts "\n[KATEGORIA]"
products = crawl_category
puts products

# 3.5 produkty z słów kluczów
puts "\n[WYSZUKIWANIE]"
KEYWORDS = [
  "laptop",
  "fotel gamingowy"
].freeze
 
keyword_products = []
 
KEYWORDS.each do |kw|
  results = crawl_search(kw, max_pages: MAX_PAGES)
  keyword_products.concat(results)
  sleep(DELAY_SEC)
end

# 4.0 szczegóły produktów
puts "\n[SZCZEGÓŁY PRODUKTÓW]"
product_urls = crawl_category_urls
detailed_products = enrich_with_details(products, product_urls)



# zapis do json
File.write(OUTPUT_FILE_3, JSON.pretty_generate(products), encoding: "utf-8")
File.write(OUTPUT_FILE_35, JSON.pretty_generate(keyword_products), encoding: "utf-8")
File.write(OUTPUT_FILE_4, JSON.pretty_generate(detailed_products), encoding: "utf-8")

puts "\nZapisano do plików: #{OUTPUT_FILE_3}, #{OUTPUT_FILE_35}, #{OUTPUT_FILE_4}"