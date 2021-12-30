import json

def search_tickers(searchQuery):
  tickers_match = []
  with open('data/company_tickers.json') as content:
    ticker_data = json.load(content)
    for i in range(len(ticker_data)):
      ticker = str(ticker_data[str(i)]['ticker'])
      company_name = str(ticker_data[str(i)]['title'])
      
      if ticker.startswith(searchQuery.upper()):
        tickers_match.append({
          "ticker": ticker,
          "company_name": company_name
        })
  json_object = {
    "count": len(tickers_match),
    "results": json.loads(json.dumps(tickers_match))
  }
  return json_object