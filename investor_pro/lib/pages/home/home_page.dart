import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class InsiderTransaction {
  final String acquistionOrDisposition;
  final String transactionDate;
  final String reportingOwner;
  final String transactionType;
  final double securitiesTransacted;
  final double securitiesOwned;
  final String securityName;

  InsiderTransaction({
    required this.acquistionOrDisposition,
    required this.transactionDate,
    required this.reportingOwner,
    required this.transactionType,
    required this.securitiesTransacted,
    required this.securitiesOwned,
    required this.securityName,
  });

  factory InsiderTransaction.fromJson(dynamic json) {
    return InsiderTransaction(
      acquistionOrDisposition: json['Acquistion or Disposition'] == 'A'
          ? 'Acquistion'
          : 'Disposition',
      transactionDate: json['Transaction Date'],
      reportingOwner: json['Reporting Owner'],
      transactionType: json['Transaction Type'],
      securitiesTransacted: json['Number of Securities Transacted'],
      securitiesOwned: json['Number of Securities Owned'],
      securityName: json['Security Name'],
    );
  }
}

class TickerAutocomplete {
  final String ticker;
  final String companyName;

  TickerAutocomplete({required this.ticker, required this.companyName});

  factory TickerAutocomplete.fromJson(dynamic json) {
    return TickerAutocomplete(
      ticker: json['ticker'],
      companyName: json['company_name'],
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late String companyName;

  Future<List<InsiderTransaction>> fetchInsiderTransactions(
      String ticker) async {
    final response = await http.get(Uri.parse(
        'http://localhost:4000/insider-trading?ticker=$ticker&page=0'));

    if (response.statusCode == 200) {
      List jsonTransactions = jsonDecode(response.body)['transactions'];
      companyName = jsonDecode(response.body)['details']['company_name'];
      return jsonTransactions
          .map((data) => InsiderTransaction.fromJson(data))
          .toList();
    } else {
      throw Exception('Failed to load insider transactions');
    }
  }

  Future<List<TickerAutocomplete>> tickerAutcomplete(String searchQuery) async {
    if (searchQuery == 'default') {
      return [
        for (int i = 0; i < 5; i++)
          TickerAutocomplete(
            ticker: 'TICKER',
            companyName: 'COMPANY_NAME',
          ),
      ];
    }

    final response = await http
        .get(Uri.parse('http://localhost:4000/search?q=$searchQuery'));

    if (response.statusCode == 200) {
      List autocompleteResults = jsonDecode(response.body)['results'];
      if (autocompleteResults.length > 5) {
        return autocompleteResults
            .map((data) => TickerAutocomplete.fromJson(data))
            .toList()
            .sublist(0, 5);
      } else {
        return autocompleteResults
            .map((data) => TickerAutocomplete.fromJson(data))
            .toList();
      }
    } else {
      throw Exception('Failed to load search autcomplete');
    }
  }

  late Future<List<InsiderTransaction>> futureInsiderTransaction;
  late Future<List<TickerAutocomplete>> futureTickerAutocomplete;
  String ticker = 'MRNA';
  String currentTicker = 'default';

  @override
  void initState() {
    super.initState();
    futureInsiderTransaction = fetchInsiderTransactions(ticker);
    futureTickerAutocomplete = tickerAutcomplete('default');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insider Transactions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: buildFloatingSearchBar(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<List<InsiderTransaction>>(
                future: fetchInsiderTransactions(ticker),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Text(companyName,
                        style: Theme.of(context).textTheme.headline5);
                  } else {
                    return const SpinKitPouringHourGlassRefined(
                        color: Colors.red, size: 40);
                  }
                },
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<InsiderTransaction>>(
              future: fetchInsiderTransactions(ticker),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  List data = snapshot.data;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              tileColor: data[index].acquistionOrDisposition ==
                                      'Acquistion'
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              // CHANGE - Only first letter capital
                              title: Column(
                                children: [
                                  Text(data[index].reportingOwner,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(data[index].securityName),
                                  Text('# Transacted: ' +
                                      data[index]
                                          .securitiesTransacted
                                          .round()
                                          .toString()),
                                  Text('# Owned: ' +
                                      data[index]
                                          .securitiesOwned
                                          .round()
                                          .toString()),
                                ],
                              ),
                              leading: Column(
                                children: [
                                  Text(companyName),
                                  Text(data[index].transactionDate),
                                  Text(data[index].acquistionOrDisposition),
                                ],
                              ),
                              trailing: Column(
                                children: [
                                  Text(data[index].transactionType),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                      child:
                          SpinKitSpinningLines(color: Colors.blue, size: 150));
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      hint: 'Ticker...',
      autocorrect: false,
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 600),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {
        setState(
          () {
            currentTicker = query;
            futureTickerAutocomplete = tickerAutcomplete(currentTicker);
          },
        );
      },
      onSubmitted: (query) {
        setState(
          () {
            ticker = query;
            futureInsiderTransaction = fetchInsiderTransactions(ticker);
          },
        );
      },
      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (BuildContext context, Animation<double> transition) {
        return Container(
          child: FutureBuilder(
            future: tickerAutcomplete(currentTicker),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Material(
                        color: Colors.white,
                        elevation: 4.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // Return search results from api
                          children: [
                            SizedBox(
                              height: 30,
                              child: Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: snapshot.data[index].ticker,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      TextSpan(
                                          text:
                                              ' (${snapshot.data[index].companyName})'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const Center(
                    child: SpinKitPouringHourGlassRefined(
                        color: Colors.red, size: 40));
              }
            },
          ),
        );
      },
    );
  }
}
