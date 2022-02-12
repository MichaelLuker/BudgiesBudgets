// Tracks the date, category, account, amount, and a memo for transactions,
//   basis of all the data stored

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/helpers/functions.dart';
import 'package:budgies_budgets/widgets/editTransaction.dart';
import 'package:flutter/material.dart';

class TransactionList extends StatefulWidget {
  final FinancialData data;
  final Function recalculate;
  const TransactionList(
      {Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  TransactionListState createState() =>
      TransactionListState(data: data, recalculate: recalculate);
}

class TransactionListState extends State<TransactionList> {
  final FinancialData data;
  final Function recalculate;
  TransactionListState(
      {Key? key, required this.data, required this.recalculate});
  bool expanded = true;
  bool confirmDelete = false;
  List<TableRow> rows = [];
  final TextStyle label = const TextStyle(color: Colors.amber);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);

  @override
  void initState() {
    super.initState();
    generateRows();
  }

  void generateRows() {
    data.sortTransactions();
    setState(() {
      rows = [];
      int count = 0;
      for (Transaction t in data.filteredTransactions) {
        TextStyle numValue = TextStyle(
            color:
                (t.amount >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
        rows.add(TableRow(
            decoration: BoxDecoration(
                color: (count % 2 == 0)
                    ? Color.fromARGB(255, 66, 66, 66)
                    : Color.fromARGB(255, 80, 80, 80)),
            children: [
              TableCell(
                  child: Column(
                children: [
                  IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return editTransaction(
                                  transaction: t,
                                  updateList: generateRows,
                                  data: data);
                            });
                      },
                      icon: Icon(Icons.edit, size: 18)),
                  IconButton(
                      onPressed: () {}, icon: Icon(Icons.copy, size: 18)),
                  IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Confirm Deletion"),
                                content: Text(
                                    "Please confirm that the transaction should be deleted...\n\n${t.toString()}"),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      )),
                                  TextButton(
                                      onPressed: () {
                                        setState(() {
                                          confirmDelete = true;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(
                                            color: Colors.lightGreenAccent),
                                      ))
                                ],
                              );
                            }).then((e) {
                          if (confirmDelete) {
                            data.allTransactions.remove(t);
                            generateRows();
                            setState(() {
                              confirmDelete = false;
                            });
                          }
                        });
                      },
                      icon: Icon(Icons.delete, size: 18))
                ],
              )),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(child: Text(formatDate(t.date)))),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                      child: Text(
                    t.account,
                    style: stringValue,
                  ))),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                    child: Text(
                      t.strAmount(),
                      style: numValue,
                      textAlign: TextAlign.end,
                    ),
                  )),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                    child: Text(t.memo),
                  )),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.image,
                      size: 18,
                    )),
              ),
            ]));
        count++;
      }
    });
    // Once the transactions have been updated run the recalculate method
    //   at this point all modifications to the transaction list should be done for now
    recalculate();
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
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool expanded) {
                return ListTile(
                    title: DropdownButton<String>(
                        alignment: Alignment.center,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                              alignment: Alignment.center,
                              value: "Transactions",
                              child: Text(
                                "Transactions",
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              )),
                          DropdownMenuItem<String>(
                              alignment: Alignment.center,
                              value: "Subscriptions",
                              child: Text(
                                "Subscriptions",
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              )),
                        ],
                        value: "Transactions",
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              data.currentUser = value;
                              recalculate(regenerateRows: true);
                            }
                          });
                        }));
              },
              body: SizedBox(
                height: 300,
                child: SingleChildScrollView(
                    child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(32),
                    // 1: FixedColumnWidth(32),
                    // 2: FixedColumnWidth(100),
                    // 3: FixedColumnWidth(120),
                    // 4: FixedColumnWidth(80),
                    5: FixedColumnWidth(32),
                  },
                  border: TableBorder.all(),
                  children: [
                        TableRow(children: [
                          TableCell(
                              child: Center(
                                  child: Text(
                            "",
                            style: label,
                          ))),
                          TableCell(
                              child: Center(
                            child: Text(
                              "Date",
                              style: label,
                            ),
                          )),
                          TableCell(
                              child: Center(
                            child: Text(
                              "Account",
                              style: label,
                            ),
                          )),
                          TableCell(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                            child: Text(
                              "Amount",
                              style: label,
                              textAlign: TextAlign.end,
                            ),
                          )),
                          TableCell(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                            child: Text(
                              "Memo",
                              style: label,
                              textAlign: TextAlign.left,
                            ),
                          )),
                          TableCell(
                              child: Center(
                                  child: Text(
                            "",
                            style: label,
                          ))),
                        ])
                      ] +
                      rows,
                )),
              ),
              isExpanded: expanded)
        ]);
  }
}
