// Scaffold of the app, controlls display of everything and initial data load
import 'dart:developer';
import 'dart:io';

import 'package:budgies_budgets/widgets/accountSelect.dart';
import 'package:budgies_budgets/widgets/newTransaction.dart';
import 'package:budgies_budgets/widgets/transactionList.dart';
import 'package:budgies_budgets/widgets/userSelect.dart';
import 'package:grizzly_io/io_loader.dart';
import 'package:svg_icon/svg_icon.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/widgets/monthSelect.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Spacer extends StatelessWidget {
  const Spacer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
    );
  }
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
  late UserSelect userSelect;
  late AccountSelect accountSelect;
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

  void loadTransactions() async {
    // Load my current transaction list
    String filePath =
        "C:\\Users\\Zhyne\\Documents\\Projects\\BudgiesBudgets\\InitialTransactions.csv";
    final csv = await readCsv(filePath);
    setState(() {
      for (List<String> row in csv) {
        Transaction t = Transaction.withValues(
            user: row[0],
            date: DateTime.parse(row[1]),
            category: categoryFromString(row[2]),
            account: row[3],
            amount: double.parse(row[4]),
            memo: row[5]);
        data.allTransactions.add(t);
      }
    });
    recalculate(regenerateRows: true);
  }

  @override
  void initState() {
    super.initState();
    // Set the initial start and end dates for a range to analyze
    data = FinancialData();
    //data.startDate = DateTime.now().subtract(const Duration(days: 30));
    data.startDate = DateTime.parse("2022-01-01");
    data.endDate = DateTime.now();
    data.users.add("Mike");
    data.currentUser = "Mike";
    //loadTransactions();
    // Instantiate the different window widgets
    userSelect = UserSelect(data: data, recalculate: recalculate);
    accountSelect = AccountSelect(data: data, recalculate: recalculate);
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
            body: SafeArea(
              child: Column(
                children: [
                  // Header elements that should always stay visible
                  userSelect,
                  accountSelect,
                  monthSelect,
                  // Scrolling on the panels
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 86),
                      child: SingleChildScrollView(
                          child: ListBody(
                        children: [
                          transactionList,
                          const Spacer(),
                        ],
                      )),
                    ),
                  )
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
