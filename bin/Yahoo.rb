require 'oauth'
require 'json'
 
 
module Yahoo
  CONSUMER_KEY    = ENV['CONSUMER_KEY']
  CONSUMER_SECRET = ENV['CONSUMER_SECRET']
 
  class YQLFinance
    def initialize(consumer_key = CONSUMER_KEY, consumer_secret = CONSUMER_SECRET)
      @consumer_key    = consumer_key
      @consumer_secret = consumer_secret
      access_token
    end
 
    def access_token
      @access_token ||= OAuth::AccessToken.new(OAuth::Consumer.new(@consumer_key, @consumer_secret, :site => "http://query.yahooapis.com"))
    end
    
    def escape string
      OAuth::Helper.escape(string)
    end
 
    def make_query_url url
      "/v1/yql?q=#{OAuth::Helper.escape(url)}&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
    end
 
    def query_api url
      JSON.parse access_token.request(:get, make_query_url(url)).body
    end

    def find_quote symbol 
      quote_url = "select * from yahoo.finance.quotes where symbol in ( '#{symbol}' )"
      Quote.new query_api(quote_url)
    end

    def find_hquote symbol, start_date, end_date
      start_date_str = start_date.strftime("%Y-%m-%d")
      end_date_str = end_date.strftime("%Y-%m-%d")      
      history_url = "select * from yahoo.finance.historicaldata where symbol = '#{symbol}' and startDate = '#{start_date_str}' and endDate = '#{end_date_str}'"
      HQuote.new query_api(history_url)
    end    

    def find sql
      query_api(sql)
    end
  end
 
  class Quote
    def initialize(response)
      @response = response
    end
 
    def output
      @response["query"]["results"]["quote"]
    end
  end
  
  class HQuote
    def initialize(response)
      @response = response
    end
    
    def output
      @response["query"]["results"]["quote"]
    end  
  end
    
end