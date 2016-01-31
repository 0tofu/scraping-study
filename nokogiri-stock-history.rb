require 'nokogiri'
require 'open-uri'

def get_nokogiri_doc(url)
  begin
    html = open(url)
  rescue OpenURI::HTTPError
    return
  end
  Nokogiri::HTML(html.read, nil, 'utf-8')
end

def has_next_page?(doc)
  doc.xpath("//*[@id='main']/ul/a").each {|element|
    return true if element.text == "次へ"
  }
  return false
end

def get_daily_data(doc)
  doc.xpath("//table[@class='boardFin yjSt marB6']/tr").each {|element|
    # 日付行及び株式分割告知を回避
    if element.children[1].text != '日付' && element.children[1][:class] != 'through'
      stock = []
      element.children.each_with_index {|child, i|
        if i <= 4
          stock.push child.text # 日付,始値,高値,安値,終値
        elsif i == 5
          stock.push child.text.gsub(/,/,'')  # 出来高
        end

      }

      # 結果出力
      puts "#{stock.join(',')}"
    end
  }
end

# 証券コード
code = '4689'

# 検索日
day = Time.now
options = {
  :sy => '1900',
  :sm => '1',
  :sd => '1',
  :ey => day.year,
  :em => day.month,
  :ed => day.day,
  :tm => 'd',
  :code => code
}

params = options.map{|key, value| "#{key}=#{value}"}.join('&')
st_url = "http://info.finance.yahoo.co.jp/history/?#{params}"
num = 1

puts "日付,始値,高値,安値,終値,出来高"
loop {
  url = "#{st_url}&p=#{num}"
  doc = get_nokogiri_doc(url)
  get_daily_data(doc)
  break unless has_next_page?(doc)
  num += 1
}