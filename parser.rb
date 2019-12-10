require 'curb'
require 'nokogiri'
require 'csv'

# Example start script: 
# ruby parser.rb https://www.petsonic.com/snacks-huesos-para-perros/ results.csv
# в curb необходимо в конце добавлять /, надо добавить проверку, если без / - дописывать самому

def get_urls_of_products(products)
  products.xpath("//a[@class='product_img_link product-list-category-img']/@href")
end

def parse_product_page(product_url, products_info)
  #puts product_url
  product_page = Nokogiri::HTML(Curl.get(product_url).body_str)

  product_name = product_page.xpath("//h1[@class='product_main_name']").text
  puts product_name

  product_img = product_page.xpath("//img[@id='bigpic']/@src")

  product_weight_list = product_page.xpath("//ul[@class='attribute_radio_list']/li")

  product_weight_list.each do |weight|
    # puts(attr)
    # product weighing
    product_weight = weight.xpath(".//span[@class='radio_label']").text

    product_price = weight.xpath(".//span[@class='price_comb']").text[/(\d+).(\d+)/]
    # final data 
    products_info << ["#{product_name} - #{product_weight}", product_price, product_img]
  end
end


def get_num_of_pages()
  category_page = Nokogiri::HTML(Curl.get($url_category).body_str)
  pages = category_page.xpath("//a[starts-with(@href,'/snacks-huesos-para-perros/?p')]/span")
  count= select_max_num(pages)
end

def select_max_num(pages)
  max_num_of_page = 0;
  pages.each do |page|
    if page.text[/(\d+)/].to_i > max_num_of_page
      max_num_of_page = page.text[/(\d+)/].to_i
    end
  end
  max_num_of_page
end

def get_products_info()
  products_info = []
  # all list of category
  page_num = 0
  count_pages = get_num_of_pages()
  while page_num <= count_pages do
    # site page url
    if page_num == 0
      page = $url_category
    else
      page = $url_category + "?p=#{page_num}"
    end
    
    page_num += 1
  
    # parse page
    category_page = Nokogiri::HTML(Curl.get(page).body_str)
    
    # break data into list of products
    products = category_page.xpath("//li[starts-with(@class, 'ajax_block_product')]")
    
    puts "Count of products on #{page_num-1} page"
    puts products.length
  
    # get all products urls
    products_url = get_urls_of_products(products)
    
    puts "Products on page:"
    # parse product page
    products_url.each do |product_url|

      parse_product_page(product_url, products_info)

    end
  end
  products_info
end

# print to csv file
def print_to_CSV(products_info)
  CSV.open($file_name, "wb") do |csv_line|
    csv_line << ['Name', 'Price', 'Image']
    products_info.each do |product|
      csv_line << product
    end
  end
end


$url_category = ARGV.first
$file_name = ARGV.last

puts "Start scraping"

products_info = get_products_info()

puts "Print to csv file"

print_to_CSV(products_info)
puts "Finish script"
