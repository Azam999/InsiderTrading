import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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

class Form4 extends StatefulWidget {
  const Form4({Key? key}) : super(key: key);

  @override
  State<Form4> createState() => _Form4State();
}

class _Form4State extends State<Form4> {
  late String companyName;
  bool isError = false;

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
      if (mounted) {
        setState(() {
          isError = true;
        });
      }
      return [
        InsiderTransaction(
          acquistionOrDisposition: 'Error',
          transactionDate: 'Error',
          reportingOwner: 'Error',
          transactionType: 'Error',
          securitiesTransacted: 0.0,
          securitiesOwned: 0.0,
          securityName: 'Error',
        )
      ];
    }
  }

  Future<List<TickerAutocomplete>> tickerAutcomplete(String searchQuery) async {
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
  String ticker = 'AAPL'; // default ticker
  String currentTicker = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form 4'),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: buildInsidersList(),
          ),
          buildFloatingSearchBar(),
        ],
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      hint: 'Enter any ticker...',
      autocorrect: false,
      automaticallyImplyBackButton: false,
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
            // CLEAR - Search bar
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
        return FutureBuilder(
          future: tickerAutcomplete(currentTicker),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return ListView.separated(
                shrinkWrap: true,
                itemCount: snapshot.data.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
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
                          ListTile(
                            title: Center(
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
                            onTap: () {
                              setState(
                                () {
                                  ticker = snapshot.data[index].ticker;
                                  futureInsiderTransaction =
                                      fetchInsiderTransactions(ticker);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: SpinKitPouringHourGlassRefined(
                  color: Colors.red,
                  size: 40,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget buildInsidersList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<List<InsiderTransaction>>(
              future: fetchInsiderTransactions(ticker),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                } else {
                  return const SpinKitPouringHourGlassRefined(
                    color: Colors.red,
                    size: 40,
                  );
                }
              },
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<InsiderTransaction>>(
            future: fetchInsiderTransactions(ticker),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (isError) {
                return alertDialog();
              } else {
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
                                  Text(
                                    data[index].reportingOwner,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(data[index].securityName),
                                  Text(
                                    '# Transacted: ' +
                                        data[index]
                                            .securitiesTransacted
                                            .round()
                                            .toString(),
                                  ),
                                  Text(
                                    '# Owned: ' +
                                        data[index]
                                            .securitiesOwned
                                            .round()
                                            .toString(),
                                  ),
                                ],
                              ),
                              leading: Column(
                                children: [
                                  Text(companyName),
                                  Text(data[index].transactionDate),
                                  Text(
                                    data[index].acquistionOrDisposition,
                                  ),
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
                    child: SpinKitSpinningLines(
                      color: Colors.blue,
                      size: 150,
                    ),
                  );
                }
              }
            },
          ),
        )
      ],
    );
  }

  Widget alertDialog() {
    return AlertDialog(
      title: const Text('Ticker not valid'),
      content: const Text('This ticker doesn\'t have insider information or is invalid.'),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('Ok'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
