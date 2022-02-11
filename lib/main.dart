// Scaffold of the app, controlls display of everything and initial data load
import 'dart:developer';

import 'package:budgies_budgets/widgets/newTransaction.dart';
import 'package:budgies_budgets/widgets/transactionList.dart';
import 'package:svg_icon/svg_icon.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/widgets/monthSelect.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budgies Budgets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const MyHomePage(title: 'Budgies Budgets'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Wait for data to be loaded before displaying widgets
  bool initialized = false;
  late FinancialData data;
  GlobalKey<TransactionListState> transactionListKey = GlobalKey();
  late MonthSelect monthSelect;
  late TransactionList transactionList;

  // Function to call all the other pieces to recalculate graphs / budgets when
  //   transactions are created, deleted, or modified
  void recalculate({bool regenerateRows = false}) {
    if (regenerateRows) {
      transactionListKey.currentState!.generateRows();
    }
    log("Reticulating Splines... Done!");
  }

  @override
  void initState() {
    super.initState();
    // Set the initial start and end dates for a range to analyze
    data = FinancialData();
    data.startDate = DateTime.now().subtract(const Duration(days: 30));
    data.endDate = DateTime.now();
    // Add an initial test transaction to display
    data.allTransactions.add(Transaction.withValues(
        id: 0,
        date: DateTime.now(),
        category: Category.Personal,
        account: Account.Visa,
        amount: -100,
        memo: "Test Transaction"));
    // Instantiate the different window widgets
    monthSelect = MonthSelect(
      data: data,
      recalculate: recalculate,
    );
    transactionList = TransactionList(
        key: transactionListKey, data: data, recalculate: recalculate);
    setState(() {
      initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return (initialized)
        ? Scaffold(
            floatingActionButton: FloatingActionButton(
              child: const SvgIcon("icons/add_card.svg"),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return newTransaction(
                        data: data,
                        updateList:
                            transactionListKey.currentState!.generateRows,
                      );
                    });
              },
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
              child: SingleChildScrollView(
                child: ListBody(
                  children: [
                    monthSelect,
                    transactionList,
                  ],
                ),
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
