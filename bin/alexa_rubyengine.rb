# Alexa RubyEngine
# This Engine receives and responds to Amazon Echo's (Alexa) JSON requests.
require 'sinatra'
require 'json'
require 'bundler/setup'
require 'alexa_rubykit'
require 'oauth'
require 'dotenv'
  
Dotenv.load

  CONSUMER_KEY    = ENV['CONSUMER_KEY']
  CONSUMER_SECRET = ENV['CONSUMER_SECRET']

# We must return application/json as our content type.
# before do
#   content_type('application/json')
# end

get '/' do
  "Hello World!"
end

#enable :sessions
post '/' do
  
  # p CONSUMER_KEY
  
  # Check that it's a valid Alexa request
  request_json = JSON.parse(request.body.read.to_s)
  # Creates a new Request object with the request parameter.
  request = AlexaRubykit.build_request(request_json)

  # We can capture Session details inside of request.
  # See session object for more information.
  session = request.session
  # p session.new?
  # p session.has_attributes?
  # p session.session_id
  # p session.user_defined?

  # We need a response object to respond to the Alexa.
  response = AlexaRubykit::Response.new

  # We can manipulate the request object.
  #
  #p "#{request.to_s}"
  #p "#{request.request_id}"

  # Response
  # If it's a launch request
  if (request.type == 'LAUNCH_REQUEST')
    # Process your Launch Request
    # Call your methods for your application here that process your Launch Request.
    response.add_speech('You can ask: What is the quote for IBM? Or just say IBM.')
    response.add_hash_card( { :title => 'Nasdaq Quotes', :subtitle => 'Diversify your portfolio!' } )
  end

  if (request.type == 'INTENT_REQUEST')
    # Process your Intent Request

    if (request.name == 'GetQuote')
      # p "#{request.slots['SymbolRequest']['value']}"
      @symbol = request.slots['SymbolRequest']['value']
      @output = YQLFinance.new.find_quote(@symbol).output
      
      if @output["LastTradePriceOnly"].nil? 
        #Yahoo could not find company.
        response.add_speech("I'm sorry, I couldn't find that listing.  I provide quote information for nasdaq symbols, like AMZN or TSLA. Now, which quote would you like? ")
      else
      
        @ltp = @output["LastTradePriceOnly"]
        @change = @output["ChangeinPercent"]
        @name = @output["Name"]
        
        
        #I need code to verify the company symbol (or name) is in custom slot values (or do i?  i  at least need to make sure it is a stock (or do I?  I could just check what yahoo returns either way)
        response.add_speech("The last traded price of #{@name} is #{@ltp}, #{@change}")
        @card_string = "#{@ltp}, #{@change}"
        response.add_hash_card( { :title => @symbol, :content => @card_string } )  
      end
    end
  end

  if (request.type =='SESSION_ENDED_REQUEST')
    # Wrap up whatever we need to do.
    # p "#{request.type}"
    # p "#{request.reason}"
    halt 200
  end

  # Return response
  response.build_response
end

# Yahoo
 

 
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
  
