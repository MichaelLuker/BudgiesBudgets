// Tracks the date, category, account, amount, and a memo for transactions,
//   basis of all the data stored

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/helpers/functions.dart';
import 'package:flutter/material.dart';

class TransactionList extends StatefulWidget {
  final FinancialData data;
  const TransactionList({Key? key, required this.data}) : super(key: key);

  @override
  TransactionListState createState() => TransactionListState(data: data);
}

class TransactionListState extends State<TransactionList> {
  final FinancialData data;
  TransactionListState({Key? key, required this.data});
  bool expanded = true;
  List<TableRow> rows = [];
  final TextStyle label = const TextStyle(color: Colors.amber);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);

  @override
  void initState() {
    super.initState();
    generateTiles();
  }

  void generateTiles() {
    setState(() {
      rows = [];
      for (Transaction t in data.transactions) {
        TextStyle numValue = TextStyle(
            color:
                (t.amount >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
        rows.add(TableRow(children: [
          TableCell(child: Center(child: Text(t.id.toString()))),
          TableCell(child: Center(child: Text(formatDate(t.date)))),
          TableCell(
              child: Center(
                  child: Text(
            t.category.toString().split(".")[1],
            style: stringValue,
          ))),
          TableCell(
              child: Center(
                  child: Text(
            t.account.toString().split(".")[1],
            style: stringValue,
          ))),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
            child: Text(
              t.strAmount(),
              style: numValue,
              textAlign: TextAlign.end,
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
            child: Text(t.memo),
          )),
        ]));
      }
    });
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
                height: 150,
                child: SingleChildScrollView(
                    child: Table(
                  border: TableBorder.all(),
                  children: [
                        TableRow(children: [
                          TableCell(
                              child: Center(
                            child: Text(
                              "Transaction ID",
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
