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
  List<TableRow> rows = [];
  final TextStyle label = const TextStyle(color: Colors.amber);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);

  @override
  void initState() {
    super.initState();
    generateRows();
  }

  void generateRows() {
    data.sort();
    setState(() {
      rows = [];
      for (Transaction t in data.filteredTransactions) {
        TextStyle numValue = TextStyle(
            color:
                (t.amount >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
        rows.add(TableRow(children: [
          TableCell(
              child: IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return editTransaction(
                            transaction: t,
                            updateList: generateRows,
                          );
                        });
                  },
                  icon: Icon(Icons.edit, size: 18))),
          TableCell(
              child: IconButton(
                  onPressed: () {
                    data.allTransactions.remove(t);
                    generateRows();
                  },
                  icon: Icon(Icons.delete, size: 18))),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text(t.id.toString()))),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text(formatDate(t.date)))),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                  child: Text(
                t.category.toString().split(".")[1],
                style: stringValue,
              ))),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                  child: Text(
                t.account.toString().split(".")[1],
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
        ]));
      }
    });
    // Once the transactions have been updated run the recalculate method
    //   at this point all modifications to the transaction list should be done for now
    recalculate();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            expanded = !isExpanded;
          });
        },
        children: [
          ExpansionPanel(
              headerBuilder: (BuildContext context, bool expanded) {
                return const ListTile(
                    title: Center(
                        child: Text(
                  "Transactions",
                  style: TextStyle(color: Color.fromARGB(255, 100, 255, 218)),
                )));
              },
              body: SizedBox(
                height: 300,
                child: SingleChildScrollView(
                    child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FixedColumnWidth(40),
                    2: FixedColumnWidth(100),
                    3: FixedColumnWidth(80),
                    4: FixedColumnWidth(80),
                    5: FixedColumnWidth(100),
                  },
                  border: TableBorder.all(),
                  children: [
                        TableRow(children: [
                          TableCell(
                              child: Center(
                                  child: Text(
                            "Edit",
                            style: label,
                          ))),
                          TableCell(
                              child: Center(
                                  child: Text(
                            "Delete",
                            style: label,
                          ))),
                          TableCell(
                              child: Center(
                            child: Text(
                              "ID",
                              style: label,
                            ),
                          )),
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
                              "Category",
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
                          ))
                        ])
                      ] +
                      rows,
                )),
              ),
              isExpanded: expanded)
        ]);
  }
}
