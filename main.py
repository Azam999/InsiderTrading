import pandas as pd
import requests
import re
from bs4 import BeautifulSoup
from itertools import groupby
import json

class InsiderTransactions:
  tickers_df = pd.read_json('data/company_tickers.json')
  tickers_df = tickers_df.transpose().set_index('ticker')

  def ticker_to_cik(self, ticker):
    raw_cik = str(self.tickers_df.loc[ticker]['cik_str'])
    cik = raw_cik.rjust(10, '0')
    return cik # Central Index Key

  def get_insider_trading_history(self, ticker, page):
    cik = self.ticker_to_cik(ticker)
    company_name = self.tickers_df.loc[ticker]['title']
    insider_trading_link = f'https://www.sec.gov/cgi-bin/own-disp?action=getissuer&CIK={cik}&type=&dateb=&owner=include&start={page * 80}'
    table = pd.read_html(insider_trading_link)

    # Dataframe that holds the list of insiders of a specific stock
    owners_df = table[5]
    owners_df = owners_df.rename(columns=owners_df.iloc[0]).drop(owners_df.index[0])
    owners_json = owners_df.to_json(orient='records')
    
    # Dataframe that holds the list of transactions made by insiders
    transactions_df = table[6]
    transactions_json = transactions_df.to_json(orient='records')
    
    json_object = {
      "details": {
        "ticker": ticker,
        "cik": cik,
        "company_name": company_name
      },
      "transactions": json.loads(transactions_json),
      "owners": json.loads(owners_json)
    }

    return json.dumps(json_object)
  