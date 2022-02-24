// ignore_for_file: file_names
// Shows a pie chart of expenses in all the different categories for the selected month.
//   if more than one month is selected then maybe show a stacked line chart of all the different
//   categories over time?
import 'dart:math';

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DataSample {
  final int category;
  final double amount;
  final String cString;
  final double budgeted;
  DataSample(this.category, this.amount, this.cString, this.budgeted);
}

class TransactionBreakdown extends StatefulWidget {
  final FinancialData data;
  const TransactionBreakdown({Key? key, required this.data}) : super(key: key);

  @override
  TransactionBreakdownState createState() =>
      TransactionBreakdownState(data: data);
}

class TransactionBreakdownState extends State<TransactionBreakdown> {
  bool expanded = true;
  final FinancialData data;
  late List<charts.Series<DataSample, int>> chartData;
  final TextStyle label = const TextStyle(color: Colors.amber, fontSize: 12);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);
  TableRow totalRow = TableRow();
  List<TableRow> rows = [];
  TextEditingController budgetController = TextEditingController();

  void updateGraph() {
    setState(() {
      chartData = [];
      rows = [];
      double totalSpent = 0;
      double totalBudgeted = 0;
      List<DataSample> categoryValues = [];
      List<List<dynamic>> tempRowData = [];

      int count = 0;
      for (Category c in Category.values) {
        // Don't include income or transfers in spending
        if (c == Category.Income || c == Category.Transfer) {
          continue;
        }
        // Get a list of transactions that match the current filters
        List<Transaction> ts = data.allTransactions
            .where((e) =>
                e.user == data.currentUser &&
                (e.account == data.currentAccount ||
                    data.currentAccount == 'All') &&
                e.category == c)
            .toList();
        // Turn that list into just the amounts
        List<double> numbers = ts.map((e) => e.amount).toList();
        // Sum all the numbers, start at 0 in case there are no matching transactions to add up
        double val = 0;
        // If there is only 1 element in the list just add it
        if (numbers.isNotEmpty && numbers.length < 2) {
          val += numbers[0];
          // If there are at least 2 elements in the list the reduce function can be used to combine all elements
        } else if (numbers.length > 2) {
          val += numbers.reduce((value, element) => value + element);
        }
        // Create a data point for the category
        DataSample sample =
            DataSample(count, val.abs(), c.toString().split('.')[1], 0.00);
        if (val != 0) {
          categoryValues.add(sample);
        }
        double budgetedAmount = 0;
        double remaining = budgetedAmount - sample.amount;
        totalSpent += sample.amount;
        totalBudgeted += budgetedAmount;

        tempRowData.add([
          (count % 2 == 0)
              ? const Color.fromARGB(255, 66, 66, 66)
              : const Color.fromARGB(255, 80, 80, 80),
          sample.cString,
          sample.amount,
          budgetedAmount,
          remaining
        ]);
        count++;
      }
      // Sort the table rows by amount spent
      tempRowData.sort((a, b) => b[2].compareTo(a[2]));
      tempRowData.forEach((element) {
        TextStyle numValue = TextStyle(
            color:
                (element[4] >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
        rows.add(
            TableRow(decoration: BoxDecoration(color: element[0]), children: [
          TableCell(
            child: Center(child: Text(element[1], style: stringValue)),
          ),
          TableCell(
            child: Center(
                child: Text("\$ " + element[2].toStringAsFixed(2).padLeft(2),
                    style: numValue)),
          ),
          TableCell(
            child: Center(
                child: Text("\$ " + element[3].toStringAsFixed(2).padLeft(2),
                    style: numValue)),
          ),
          TableCell(
            child: Center(
                child: Text("\$ " + element[4].toStringAsFixed(2).padLeft(2),
                    style: numValue)),
          ),
          TableCell(
            child: IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(builder: (context, setState) {
                          return AlertDialog(
                              titlePadding: const EdgeInsets.all(8),
                              contentPadding: const EdgeInsets.all(8),
                              title: const Text("New Account"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.redAccent),
                                    )),
                                TextButton(
                                    onPressed: () {
                                      // Actions to set a budget
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "Confirm",
                                      style: TextStyle(
                                          color: Colors.lightGreenAccent),
                                    ))
                              ],
                              content: SingleChildScrollView(
                                  child: ListBody(
                                children: [
                                  // Budget Amount
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Flexible(
                                          flex: 0, child: Text("Amount:   ")),
                                      Expanded(
                                          flex: 3,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: budgetController,
                                            style: const TextStyle(
                                                color: Colors.lightBlueAccent),
                                          )),
                                    ],
                                  ),
                                ],
                              )));
                        });
                      });
                },
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                )),
          )
        ]));
      });
      // Set the values for the row that shows the total values
      double totalRemaining = totalBudgeted - totalSpent;
      TextStyle numValue = TextStyle(
          color: (totalRemaining >= 0)
              ? Colors.lightGreenAccent
              : Colors.redAccent);
      totalRow = TableRow(
          decoration:
              BoxDecoration(color: const Color.fromARGB(255, 66, 66, 66)),
          children: [
            TableCell(
              child: Center(child: Text("Totals", style: stringValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + totalSpent.toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + totalBudgeted.toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + totalRemaining.toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(child: Container())
          ]);
      categoryValues
          .sort((DataSample a, DataSample b) => b.amount.compareTo(a.amount));
      // At this point each category should have a value associated with it
      chartData = [
        charts.Series<DataSample, int>(
            id: 'Transactions',
            domainFn: (DataSample d, _) => d.category,
            measureFn: (DataSample d, _) => d.amount,
            labelAccessorFn: (DataSample row, _) => '${row.cString}',
            data: categoryValues)
      ];
    });
  }

  TransactionBreakdownState({required this.data});

  @override
  void initState() {
    super.initState();
    updateGraph();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            expanded = !isExpanded;
          });
        },
        children: [
          ExpansionPanel(
              isExpanded: expanded,
              headerBuilder: (BuildContext context, bool expanded) {
                return const ListTile(
                    title: Center(child: Text("            Spending")));
              },
              body: SingleChildScrollView(
                  child: Column(
                children: [
                  SizedBox(
                      width: 350,
                      height: 350,
                      child: charts.PieChart<int>(
                        chartData,
                        animate: false,
                        defaultRenderer: charts.ArcRendererConfig(
                            arcRatio: 0.65,
                            arcRendererDecorators: [
                              charts.ArcLabelDecorator(
                                  labelPadding: 0,
                                  labelPosition: charts.ArcLabelPosition.auto,
                                  leaderLineStyleSpec:
                                      charts.ArcLabelLeaderLineStyleSpec(
                                          color: charts.Color.fromHex(
                                              code: "#FFFFFF"),
                                          length: 10,
                                          thickness: 1),
                                  insideLabelStyleSpec: charts.TextStyleSpec(
                                      fontSize: 12,
                                      color: charts.Color.fromHex(
                                          code: "#FFFFFF")),
                                  outsideLabelStyleSpec: charts.TextStyleSpec(
                                      fontSize: 12,
                                      color: charts.Color.fromHex(
                                          code: "#FFFFFF")))
                            ]),
                      )),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(),
                    columnWidths: const {4: FixedColumnWidth(32)},
                    children: <TableRow>[
                          TableRow(children: [
                            TableCell(
                              child:
                                  Center(child: Text("Category", style: label)),
                            ),
                            TableCell(
                              child: Center(child: Text("Spent", style: label)),
                            ),
                            TableCell(
                              child:
                                  Center(child: Text("Budgeted", style: label)),
                            ),
                            TableCell(
                              child: Center(
                                  child: Text("Remaining", style: label)),
                            ),
                            const TableCell(
                              child: Center(child: Text("")),
                            )
                          ]),
                        ] +
                        [totalRow] +
                        rows,
                  )
                ],
              )))
        ]);
  }
}
