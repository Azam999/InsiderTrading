from flask import Flask
from flask import request
from main import InsiderTransactions
from search import search_tickers

app = Flask(__name__)

@app.route('/')
def index():
  return 'API'

@app.route("/insider-trading")
def insider_history():
  ticker = request.args.get('ticker').upper()
  page = request.args.get('page')
  it = InsiderTransactions()
  result = it.get_insider_trading_history(ticker, int(page))
  return result

@app.route("/search")
def search():
  query = request.args.get('q')
  result = search_tickers(query)
  return result