require "nokogiri"
require "net/http"
require "uri"
require "json"

# konfiguracja
BASE_URL = "https://www.morele.net"
CATEGORY_PATH = "/kategoria/fotele-gamingowe-747"
MAX_PAGES = 1 # ile stron kategorii pobrać (0 = wszystkie)
DELAY_SEC = 1.5 # opóźnienie między żądaniami
OUTPUT_FILE = "produkty3_0.json"

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

# main
products = crawl_category
puts products

# zapis do json
File.write(OUTPUT_FILE, JSON.pretty_generate(products), encoding: "utf-8")

puts "\nZapisano #{products.size} produktów do pliku: #{OUTPUT_FILE}"