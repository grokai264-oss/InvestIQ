/// Local NSE equity catalog for instant search (no network).
class EquityEntry {
  final String symbol;
  final String name;
  const EquityEntry(this.symbol, this.name);
}

const List<EquityEntry> kEquityCatalog = [
  EquityEntry('RELIANCE', 'Reliance Industries'),
  EquityEntry('TCS', 'Tata Consultancy Services'),
  EquityEntry('INFY', 'Infosys'),
  EquityEntry('HDFCBANK', 'HDFC Bank'),
  EquityEntry('ICICIBANK', 'ICICI Bank'),
  EquityEntry('SBIN', 'State Bank of India'),
  EquityEntry('BHARTIARTL', 'Bharti Airtel'),
  EquityEntry('ITC', 'ITC'),
  EquityEntry('KOTAKBANK', 'Kotak Mahindra Bank'),
  EquityEntry('LT', 'Larsen & Toubro'),
  EquityEntry('BEL', 'Bharat Electronics'),
  EquityEntry('HINDUNILVR', 'Hindustan Unilever'),
  EquityEntry('AXISBANK', 'Axis Bank'),
  EquityEntry('BAJFINANCE', 'Bajaj Finance'),
  EquityEntry('ASIANPAINT', 'Asian Paints'),
  EquityEntry('MARUTI', 'Maruti Suzuki'),
  EquityEntry('SUNPHARMA', 'Sun Pharma'),
  EquityEntry('TITAN', 'Titan Company'),
  EquityEntry('WIPRO', 'Wipro'),
  EquityEntry('NTPC', 'NTPC'),
  EquityEntry('POWERGRID', 'Power Grid'),
  EquityEntry('ONGC', 'ONGC'),
  EquityEntry('TATAMOTORS', 'Tata Motors'),
  EquityEntry('TATASTEEL', 'Tata Steel'),
  EquityEntry('JSWSTEEL', 'JSW Steel'),
  EquityEntry('ADANIENT', 'Adani Enterprises'),
  EquityEntry('ADANIPORTS', 'Adani Ports'),
  EquityEntry('ULTRACEMCO', 'UltraTech Cement'),
  EquityEntry('NESTLEIND', 'Nestle India'),
  EquityEntry('HCLTECH', 'HCL Technologies'),
  EquityEntry('TECHM', 'Tech Mahindra'),
  EquityEntry('INDUSINDBK', 'IndusInd Bank'),
  EquityEntry('BAJAJFINSV', 'Bajaj Finserv'),
  EquityEntry('M&M', 'Mahindra & Mahindra'),
  EquityEntry('COALINDIA', 'Coal India'),
  EquityEntry('BPCL', 'Bharat Petroleum'),
  EquityEntry('HPCL', 'Hindustan Petroleum'),
  EquityEntry('IOC', 'Indian Oil'),
  EquityEntry('GRASIM', 'Grasim'),
  EquityEntry('CIPLA', 'Cipla'),
  EquityEntry('DRREDDY', "Dr Reddy's"),
  EquityEntry('DIVISLAB', "Divi's Labs"),
  EquityEntry('EICHERMOT', 'Eicher Motors'),
  EquityEntry('HEROMOTOCO', 'Hero MotoCorp'),
  EquityEntry('BRITANNIA', 'Britannia'),
  EquityEntry('APOLLOHOSP', 'Apollo Hospitals'),
  EquityEntry('HDFCLIFE', 'HDFC Life'),
  EquityEntry('SBILIFE', 'SBI Life'),
  EquityEntry('PIDILITIND', 'Pidilite'),
  EquityEntry('DABUR', 'Dabur'),
  EquityEntry('GODREJCP', 'Godrej Consumer'),
  EquityEntry('HAVELLS', 'Havells'),
  EquityEntry('SIEMENS', 'Siemens'),
  EquityEntry('DLF', 'DLF'),
  EquityEntry('ZOMATO', 'Zomato'),
  EquityEntry('PAYTM', 'Paytm'),
  EquityEntry('NYKAA', 'Nykaa'),
  EquityEntry('IRCTC', 'IRCTC'),
  EquityEntry('IRFC', 'IRFC'),
  EquityEntry('HAL', 'Hindustan Aeronautics'),
  EquityEntry('BHEL', 'BHEL'),
  EquityEntry('SAIL', 'SAIL'),
  EquityEntry('VEDL', 'Vedanta'),
  EquityEntry('HINDALCO', 'Hindalco'),
  EquityEntry('PNB', 'Punjab National Bank'),
  EquityEntry('BANKBARODA', 'Bank of Baroda'),
  EquityEntry('CANBK', 'Canara Bank'),
  EquityEntry('FEDERALBNK', 'Federal Bank'),
  EquityEntry('IDFCFIRSTB', 'IDFC First Bank'),
  EquityEntry('AUROPHARMA', 'Aurobindo Pharma'),
  EquityEntry('LUPIN', 'Lupin'),
  EquityEntry('BIOCON', 'Biocon'),
  EquityEntry('AMBUJACEM', 'Ambuja Cements'),
  EquityEntry('SHREECEM', 'Shree Cement'),
  EquityEntry('ACC', 'ACC'),
  EquityEntry('INDIGO', 'InterGlobe Aviation'),
  EquityEntry('NAUKRI', 'Info Edge'),
  EquityEntry('DMART', 'Avenue Supermarts'),
  EquityEntry('TRENT', 'Trent'),
  EquityEntry('PAGEIND', 'Page Industries'),
  EquityEntry('BERGEPAINT', 'Berger Paints'),
  EquityEntry('COLPAL', 'Colgate-Palmolive'),
  EquityEntry('MARICO', 'Marico'),
  EquityEntry('UBL', 'United Breweries'),
  EquityEntry('MCDOWELL-N', 'United Spirits'),
  EquityEntry('GAIL', 'GAIL'),
  EquityEntry('PETRONET', 'Petronet LNG'),
  EquityEntry('RECLTD', 'REC'),
  EquityEntry('PFC', 'Power Finance'),
  EquityEntry('NHPC', 'NHPC'),
  EquityEntry('SJVN', 'SJVN'),
  EquityEntry('YESBANK', 'Yes Bank'),
  EquityEntry('IDEA', 'Vodafone Idea'),
  EquityEntry('TATAPOWER', 'Tata Power'),
  EquityEntry('ADANIGREEN', 'Adani Green'),
  EquityEntry('ADANIPOWER', 'Adani Power'),
  EquityEntry('JIOFIN', 'Jio Financial'),
  EquityEntry('POLYCAB', 'Polycab'),
  EquityEntry('CGPOWER', 'CG Power'),
  EquityEntry('PERSISTENT', 'Persistent Systems'),
  EquityEntry('COFORGE', 'Coforge'),
  EquityEntry('MPHASIS', 'Mphasis'),
  EquityEntry('LTIM', 'LTIMindtree'),
  EquityEntry('OFSS', 'Oracle Financial Services'),
  EquityEntry('ABB', 'ABB India'),
  EquityEntry('HINDPETRO', 'Hindustan Petroleum'),
];

List<EquityEntry> searchLocal(String query, {int limit = 40}) {
  final q = query.trim().toUpperCase();
  if (q.isEmpty) {
    return kEquityCatalog.take(limit).toList();
  }
  final out = <EquityEntry>[];
  // Prefer symbol prefix matches first
  for (final e in kEquityCatalog) {
    if (e.symbol.startsWith(q)) {
      out.add(e);
      if (out.length >= limit) return out;
    }
  }
  for (final e in kEquityCatalog) {
    if (out.any((x) => x.symbol == e.symbol)) continue;
    if (e.symbol.contains(q) || e.name.toUpperCase().contains(q)) {
      out.add(e);
      if (out.length >= limit) break;
    }
  }
  return out;
}
