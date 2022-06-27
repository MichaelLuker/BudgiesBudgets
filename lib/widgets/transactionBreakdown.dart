// ignore_for_file: file_names
// Shows a pie chart of expenses in all the different categories for the selected month.
//   if more than one month is selected then maybe show a stacked line chart of all the different
//   categories over time?
import 'dart:math';
import 'dart:developer' as dev;

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DataSample {
  final int category;
  final double amount;
  final String cString;
  final double budgeted;
  final int dateKey;
  DataSample(this.category, this.amount, this.cString, this.budgeted,
      {this.dateKey = 0});
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
  late List<charts.Series<DataSample, String>> lineData;
  final TextStyle label = const TextStyle(color: Colors.amber, fontSize: 12);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);
  TableRow totalRow = TableRow();
  List<TableRow> rows = [];
  TextEditingController budgetController = TextEditingController();
  bool isLineGraph = false;

  Map<String, dynamic> updatePieChart() {
    int count = 0;
    double totalSpent = 0;
    double totalBudgeted = 0;
    List<List<dynamic>> tempRowData = [];
    List<DataSample> categoryValues = [];
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
      } else if (numbers.length >= 2) {
        val += numbers.reduce((value, element) => value + element);
      }
      // Create a data point for the category
      DataSample sample =
          DataSample(count, val.abs(), c.toString().split('.')[1], 0.00);
      if (val != 0) {
        categoryValues.add(sample);
      }
      double budgetedAmount = 0;
      if (data.budgets.containsKey(data.currentUser)) {
        var temp = data.budgets[data.currentUser]!
            .where((element) => element.category == c);
        if (temp.isNotEmpty) {
          budgetedAmount = temp.first.amount;
        }
      }
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
    return {
      "rd": tempRowData,
      "cv": categoryValues,
      "tb": totalBudgeted,
      "ts": totalSpent
    };
  }

  Map<String, dynamic> updateLineGraph() {
    int count = 0;
    double totalSpent = 0;
    double totalBudgeted = 0;
    Map<String, List<dynamic>> tempRowData = {};
    List<charts.Series<DataSample, String>> categoryValues = [];

    // Start by getting a list of date strings for the year and months
    DateTime end = data.endDate;
    List<String> dateStrings = [];
    while (data.startDate.isBefore(end)) {
      dateStrings.add("${end.year}-${end.month.toString().padLeft(2, "0")}");
      end = DateTime(end.year, end.month - 1, end.day);
    }

    // For each Category
    for (Category c in Category.values) {
      // Don't include income or transfers in spending
      if (c == Category.Income || c == Category.Transfer) {
        continue;
      }
      List<DataSample> monthData = [];
      int monthCount = 1;
      for (String m in dateStrings) {
        // Get a list of the transactions that match
        List<Transaction> ts = data.allTransactions
            .where((e) =>
                e.date.toString().startsWith(m) &&
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
        } else if (numbers.length >= 2) {
          val += numbers.reduce((value, element) => value + element);
        }
        // Create a data point for the category and date
        DataSample sample = DataSample(
            count, val.abs(), c.toString().split('.')[1], 0.00,
            dateKey: monthCount);
        if (val != 0) {
          monthData.add(sample);
        }
        double budgetedAmount = 0;
        if (data.budgets.containsKey(data.currentUser)) {
          var temp = data.budgets[data.currentUser]!
              .where((element) => element.category == c);
          if (temp.isNotEmpty) {
            budgetedAmount = temp.first.amount;
          }
        }
        double remaining = budgetedAmount - sample.amount;
        totalSpent += sample.amount;
        totalBudgeted += budgetedAmount;

        if (!tempRowData.containsKey(sample.cString)) {
          tempRowData[sample.cString] = [
            (count % 2 == 0)
                ? const Color.fromARGB(255, 66, 66, 66)
                : const Color.fromARGB(255, 80, 80, 80),
            sample.cString,
            sample.amount,
            budgetedAmount,
            remaining,
          ];
        } else {
          tempRowData[sample.cString]![2] += sample.amount;
          tempRowData[sample.cString]![3] += budgetedAmount;
          tempRowData[sample.cString]![4] += remaining;
        }

        count++;
        monthCount++;
      }
      // Get a sum of the transactions for each month
      // for something
      // Now add this categories values to the full set

      categoryValues.add(charts.Series<DataSample, String>(
        id: c.name,
        //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (DataSample e, _) => e.dateKey.toString(),
        measureFn: (DataSample e, _) => e.amount,
        data: monthData,
      ));
    }

    return {
      "rd": tempRowData.entries.map((e) => e.value).toList(),
      "cv": categoryValues,
      "tb": totalBudgeted,
      "ts": totalSpent
    };
  }

  void addRow(dynamic element) {
    TextStyle numValue = TextStyle(
        color: (element[4] >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
    rows.add(TableRow(decoration: BoxDecoration(color: element[0]), children: [
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
                          title: const Text("Budgeted Amount"),
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
                                  Budget b = Budget(
                                      user: data.currentUser,
                                      category: categoryFromString(element[1]),
                                      amount:
                                          double.parse(budgetController.text));
                                  writeBudget(b);
                                  if (data.budgets
                                      .containsKey(data.currentUser)) {
                                    var temp = data.budgets[data.currentUser]!
                                        .where((e) =>
                                            e.category ==
                                            categoryFromString(element[1]));
                                    if (temp.isEmpty) {
                                      data.budgets[data.currentUser]!.add(b);
                                    } else {
                                      for (int i = 0;
                                          i <
                                              data.budgets[data.currentUser]!
                                                  .length;
                                          i++) {
                                        if (data.budgets[data.currentUser]![
                                                i] ==
                                            temp.first) {
                                          data.budgets[data.currentUser]![i]
                                                  .amount =
                                              double.parse(
                                                  budgetController.text);
                                        }
                                      }
                                    }
                                  } else {
                                    data.budgets[data.currentUser] = [b];
                                  }

                                  updateGraph();
                                  budgetController.text = "";
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  "Confirm",
                                  style:
                                      TextStyle(color: Colors.lightGreenAccent),
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
                                        keyboardType: const TextInputType
                                                .numberWithOptions(
                                            signed: true, decimal: true),
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
  }

  void updateGraph() {
    setState(() {
      chartData = [];
      lineData = [];
      rows = [];
      Map<String, dynamic> temp;
      // If there are 60 days in the range switch to a line graph
      isLineGraph =
          data.endDate.difference(data.startDate) > const Duration(days: 55);
      if (isLineGraph) {
        temp = updateLineGraph();
      } else {
        temp = updatePieChart();
      }

      // Sort the table rows by amount spent
      List<dynamic> r = temp['rd'];
      r.sort((a, b) => b[2].compareTo(a[2]));
      // Fix the background colors of the rows
      for (int i = 0; i < r.length; i++) {
        r[i][0] = (i % 2 == 0)
            ? const Color.fromARGB(255, 66, 66, 66)
            : const Color.fromARGB(255, 80, 80, 80);
      }
      r.forEach(addRow);
      // Set the values for the row that shows the total values
      double totalRemaining = temp['tb'] - temp['ts'];
      TextStyle numValue = TextStyle(
          color: (totalRemaining >= 0)
              ? Colors.lightGreenAccent
              : Colors.redAccent);
      totalRow = TableRow(
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 80, 80, 80)),
          children: [
            TableCell(
              child: Center(child: Text("Totals", style: stringValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + temp['ts'].toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + temp['tb'].toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(
              child: Center(
                  child: Text("\$ " + totalRemaining.toStringAsFixed(2),
                      style: numValue)),
            ),
            TableCell(child: Container())
          ]);
      if (isLineGraph) {
        lineData = temp['cv'];
      } else {
        temp['cv']
            .sort((DataSample a, DataSample b) => b.amount.compareTo(a.amount));
        // At this point each category should have a value associated with it
        chartData = [
          charts.Series<DataSample, int>(
              id: 'Transactions',
              domainFn: (DataSample d, _) => d.category,
              measureFn: (DataSample d, _) => d.amount,
              labelAccessorFn: (DataSample row, _) => '${row.cString}',
              data: temp['cv'])
        ];
      }
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
                      height: 300,
                      child: (isLineGraph)
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: charts.BarChart(
                                lineData,

                                /// Customize the primary measure axis using a small tick renderer.
                                /// Use String instead of num for ordinal domain axis
                                /// (typically bar charts).
                                primaryMeasureAxis:
                                    const charts.NumericAxisSpec(
                                        renderSpec: charts.GridlineRendererSpec(
                                  labelStyle: charts.TextStyleSpec(
                                      color: charts.MaterialPalette.white),
                                  labelAnchor: charts.TickLabelAnchor.before,
                                  labelJustification:
                                      charts.TickLabelJustification.outside,
                                )),
                                animate: false,
                                behaviors: [
                                  charts.SeriesLegend(
                                    position: charts.BehaviorPosition.end,
                                    outsideJustification:
                                        charts.OutsideJustification.endDrawArea,
                                    horizontalFirst: false,
                                    desiredMaxRows: 11,
                                    cellPadding: const EdgeInsets.only(
                                        right: 4.0, bottom: 4.0),
                                  )
                                ],
                              ),
                            )
                          : charts.PieChart<int>(
                              chartData,
                              animate: false,
                              defaultRenderer: charts.ArcRendererConfig(
                                  arcRatio: 0.65,
                                  arcRendererDecorators: [
                                    charts.ArcLabelDecorator(
                                        labelPadding: 0,
                                        labelPosition: charts
                                            .ArcLabelPosition.auto,
                                        leaderLineStyleSpec:
                                            charts.ArcLabelLeaderLineStyleSpec(
                                                color: charts.Color.fromHex(
                                                    code: "#FFFFFF"),
                                                length: 10,
                                                thickness: 1),
                                        insideLabelStyleSpec:
                                            charts.TextStyleSpec(
                                                fontSize: 12,
                                                color: charts.Color.fromHex(
                                                    code: "#FFFFFF")),
                                        outsideLabelStyleSpec:
                                            charts.TextStyleSpec(
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
