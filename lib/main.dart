// Scaffold of the app, controlls display of everything and initial data load
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:budgies_budgets/helpers/backendRequests.dart';
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
  bool initialized = false;
  bool calledOnce = false;
  late FinancialData data;
  GlobalKey<TransactionListState> transactionListKey = GlobalKey();
  GlobalKey<AccountSelectState> accountSelectKey = GlobalKey();
  late UserSelect userSelect;
  late AccountSelect accountSelect;
  late MonthSelect monthSelect;
  late TransactionList transactionList;

  // Function to call all the other pieces to recalculate graphs / budgets when
  //   transactions are created, deleted, or modified
  void recalculate(
      {bool regenerateRows = false, bool updateAccountDropdowns = false}) {
    log("Reticulating Splines...");
    if (regenerateRows) {
      transactionListKey.currentState?.generateRows();
    }
    if (updateAccountDropdowns) {
      accountSelectKey.currentState?.updateAccountDropdown();
    }
    log("Done!");
  }

  Future<FinancialData> loadInitialTransactions() async {
    // Reading in some test data from a csv file
    // Windows path
    String filePath =
        "C:\\Users\\Zhyne\\Documents\\Projects\\BudgiesBudgets\\InitialTransactions.csv";
    // Android path
    // String filePath =
    //     "/data/user/0/com.example.budgies_budgets/cache/file_picker/InitialTransactions.csv";
    final csv = await readCsv(filePath);
    FinancialData fd = FinancialData();
    // Add all the transactions, from the transactions also add in the users and empty basic accounts
    setState(() {
      for (List<String> row in csv) {
        Transaction t = Transaction.withValues(
            user: row[0],
            date: DateTime.parse(row[1]),
            category: categoryFromString(row[2]),
            account: row[3],
            amount: double.parse(row[4]),
            memo: row[5]);
        t.guid = generateGUID(t);
        fd.allTransactions.add(t);
        if (!fd.users.contains(row[0])) {
          fd.users.add(row[0]);
        }
      }
    });
    for (String user in fd.users) {
      fd.accounts.add(Account.withValues(
          user: user, name: "Savings", balance: 0.0, isGiftcard: false));
      fd.accounts.add(Account.withValues(
          user: user, name: "Checking", balance: 0.0, isGiftcard: false));
      fd.accounts.add(Account.withValues(
          user: user, name: "Visa", balance: 0.0, isGiftcard: false));
    }
    fd.currentUser = fd.users[0];
    fd.startDate = DateTime.parse("2022-01-01");
    fd.endDate = DateTime.now();
    fd.sortAccounts();
    fd.sortTransactions();
    return fd;
    // Taking a test blob from python output to see if compression / decompressiong works
    // data.startDate = DateTime.now().subtract(const Duration(days: 30));
    // data.startDate = DateTime.parse("2022-01-01");
    // data.endDate = DateTime.now();
    // String compressedTestTransactions = "'H4sIAAUlDWIC/8VdXXebSLb9S4Dg3puH+yAbiUbLVSxkJFL1FktzBQVksqbtAPXr796ldE+mxzCRnW7WLK/0JP6Qjs85e...TxFqFkn4OzU/VcbeDyU/Z8oG+Hv2JO6uNH73//HwunPqI0fgAA'";
    // return FinancialData.fromJson(
    //     decompressData(compressedTestTransactions),
    //     DateTimeRange(
    //         start: DateTime.parse("2022-01-01"), end: DateTime.now()));
  }

  void loadDataThenWidgets() async {
    data = await loadInitialTransactions();
    setState(() {
      userSelect = UserSelect(data: data, recalculate: recalculate);
      accountSelect = AccountSelect(
          key: accountSelectKey, data: data, recalculate: recalculate);
      monthSelect = MonthSelect(
        data: data,
        recalculate: recalculate,
      );
      transactionList = TransactionList(
          key: transactionListKey, data: data, recalculate: recalculate);
      initialized = true;
    });
  }

  @override
  void initState() {
    super.initState();
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
