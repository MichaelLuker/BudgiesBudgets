// Scaffold of the app, controlls display of everything and initial data load
// ignore_for_file: avoid_init_to_null

import 'dart:developer';
import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:budgies_budgets/widgets/accountList.dart';
import 'package:budgies_budgets/widgets/accountSelect.dart';
import 'package:budgies_budgets/widgets/newTransaction.dart';
import 'package:budgies_budgets/widgets/transactionBreakdown.dart';
import 'package:budgies_budgets/widgets/transactionList.dart';
import 'package:budgies_budgets/widgets/userSelect.dart';
import 'package:svg_icon/svg_icon.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/widgets/monthSelect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class Spacer extends StatelessWidget {
  const Spacer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool initialized = false;
  bool calledOnce = false;
  late FinancialData data;
  GlobalKey<TransactionListState> transactionListKey = GlobalKey();
  GlobalKey<AccountListState> accountListKey = GlobalKey();
  GlobalKey<AccountSelectState> accountSelectKey = GlobalKey();
  GlobalKey<TransactionBreakdownState> transactionBreakdownKey = GlobalKey();
  late UserSelect userSelect;
  late AccountSelect accountSelect;
  late MonthSelect monthSelect;
  late TransactionList transactionList;
  late AccountList accountList;
  late TransactionBreakdown transactionBreakdown;
  late AnimationController syncAnimationController;
  bool syncing = false;

  // Function to call all the other pieces to recalculate graphs / budgets when
  //   transactions are created, deleted, or modified
  void recalculate(
      {bool regenerateRows = false,
      bool updateAccountDropdowns = false,
      bool updateAccountList = false,
      bool updateGraphs = false,
      Transaction? t = null,
      String? action = null,
      double? oldValue = null}) {
    log("Reticulating Splines...");
    // If a transaction is sent apply the modification to the account then do the row regen
    if (t != null && action != null) {
      switch (action) {
        case "add":
          data.accounts
              .firstWhere((a) => t.user == a.user && t.account == a.name)
              .balance += t.amount;
          break;
        case "modify":
          data.accounts
              .firstWhere((a) => t.user == a.user && t.account == a.name)
              .balance += t.amount - oldValue!;
          break;
        case "delete":
          data.accounts
              .firstWhere((a) => t.user == a.user && t.account == a.name)
              .balance -= t.amount;
          break;
      }
      modifyAccount(data.accounts
          .firstWhere((a) => t.user == a.user && t.account == a.name));
    }
    if (updateGraphs) {
      transactionBreakdownKey.currentState?.updateGraph();
    }
    if (regenerateRows) {
      transactionListKey.currentState?.generateRows();
    }
    if (updateAccountDropdowns) {
      accountSelectKey.currentState?.updateAccountDropdown();
    }
    if (updateAccountList) {
      accountListKey.currentState?.generateRows();
    }

    log("Done!");
  }

  // Pull down data from the backend, compare to see what needs to be added
  Future<void> syncData() async {
    // First get the data from the backend
    FinancialData temp = await getAllFinancialData(
        DateTimeRange(start: data.startDate, end: data.endDate));
    // Pull the backend data again, it's the authoritative source
    setState(() {
      data.accounts = temp.accounts;
      data.allTransactions = temp.allTransactions;
      data.startDate = temp.startDate;
      data.endDate = temp.endDate;
      syncing = false;
      syncAnimationController.stop();
      syncAnimationController.reset();
    });
  }

  void loadDataThenWidgets() async {
    // Start with a month to date view
    var now = DateTime.now();
    data = await getAllFinancialData(DateTimeRange(
        start: DateTime.parse(
            "${now.year}-${now.month.toString().padLeft(2, "0")}-01"),
        end: now));
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Check if there is a previously set user to start with
      if (prefs.containsKey('currentUser')) {
        data.currentUser = prefs.getString('currentUser')!;
      }
      userSelect = UserSelect(data: data, recalculate: recalculate);
      accountSelect = AccountSelect(
          key: accountSelectKey, data: data, recalculate: recalculate);
      monthSelect = MonthSelect(
        data: data,
        recalculate: recalculate,
      );
      transactionList = TransactionList(
          key: transactionListKey, data: data, recalculate: recalculate);
      accountList = AccountList(
          key: accountListKey, data: data, recalculate: recalculate);
      transactionBreakdown =
          TransactionBreakdown(key: transactionBreakdownKey, data: data);
      initialized = true;
    });
  }

  @override
  void initState() {
    super.initState();
    syncAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    loadDataThenWidgets();
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
                        recalculate: recalculate,
                      );
                    });
              },
            ),
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                    child: FloatingActionButton(
                        onPressed: () async {
                          if (!syncing) {
                            setState(() {
                              syncing = true;
                              syncAnimationController.repeat();
                            });
                            await syncData();
                            recalculate(
                                regenerateRows: true,
                                updateAccountDropdowns: true,
                                updateGraphs: true);
                          }
                        },
                        child: RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0)
                              .animate(syncAnimationController),
                          child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: const Icon(Icons.sync)),
                        )),
                  ),
                ),
                SafeArea(
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
                              accountList,
                              const Spacer(),
                              transactionBreakdown,
                              const Spacer(),
                            ],
                          )),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
