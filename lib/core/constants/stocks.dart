/// Configurable tick rate.
/// Default: 200 ms → ~5 ticks/sec overall.
/// Set to 20 for stress test: ~50 ticks/sec overall (5+ ticks/sec per stock on average).
const int kTickIntervalMs = 200;

/// Starting wallet balance.
const double kInitialWalletBalance = 1000000.0; // ₹10,00,000

/// Immutable descriptor for one of the 10 supported stocks.
class StockInfo {
  final String symbol;
  final String name;
  final double startingPrice;

  const StockInfo({
    required this.symbol,
    required this.name,
    required this.startingPrice,
  });
}

/// The 10 NSE stocks used throughout the app.
const List<StockInfo> kStocks = [
  StockInfo(symbol: 'RELIANCE',   name: 'Reliance Industries',      startingPrice: 2850.75),
  StockInfo(symbol: 'TCS',        name: 'Tata Consultancy Services', startingPrice: 4125.50),
  StockInfo(symbol: 'INFY',       name: 'Infosys Ltd.',              startingPrice: 1890.25),
  StockInfo(symbol: 'HDFCBANK',   name: 'HDFC Bank Ltd.',            startingPrice: 1720.60),
  StockInfo(symbol: 'ICICIBANK',  name: 'ICICI Bank Ltd.',           startingPrice: 1285.30),
  StockInfo(symbol: 'SBIN',       name: 'State Bank of India',       startingPrice:  892.45),
  StockInfo(symbol: 'ITC',        name: 'ITC Ltd.',                  startingPrice:  478.90),
  StockInfo(symbol: 'LT',         name: 'Larsen & Toubro Ltd.',      startingPrice: 3650.15),
  StockInfo(symbol: 'BHARTIARTL', name: 'Bharti Airtel Ltd.',        startingPrice: 1920.80),
  StockInfo(symbol: 'AXISBANK',   name: 'Axis Bank Ltd.',            startingPrice: 1175.35),
];

/// Quick lookup list of symbols.
final List<String> kAllSymbols = kStocks.map((s) => s.symbol).toList();

/// Quick lookup map: symbol → StockInfo.
final Map<String, StockInfo> kStockMap = {
  for (final s in kStocks) s.symbol: s
};
