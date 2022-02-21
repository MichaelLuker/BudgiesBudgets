// Tracks the date, category, account, amount, and a memo for transactions,
//   basis of all the data stored

import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/widgets/editTransaction.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

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
  final TextStyle label = const TextStyle(color: Colors.amber, fontSize: 12);
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
                    ? const Color.fromARGB(255, 66, 66, 66)
                    : const Color.fromARGB(255, 80, 80, 80)),
            children: [
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(
                    child: IconButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return editTransaction(
                                    transaction: t,
                                    recalculate: recalculate,
                                    data: data);
                              });
                        },
                        icon: const Icon(Icons.menu, size: 18)),
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
                      "\$ " + t.strAmount(),
                      style: numValue,
                      textAlign: TextAlign.end,
                    ),
                  )),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Center(child: categoryToIcon(t.category, 18))),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                      child: Text(t.memo))),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: (t.hasMemoImage)
                    ? IconButton(
                        onPressed: () async {
                          // If it's marked as having an image but the widget isn't there
                          //   get the image from the backend and then display it
                          t.memoImageWidget ??= InteractiveViewer(
                              child: Image.memory(await getMemoImage(t.guid)));
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("Close"))
                                ], content: t.memoImageWidget);
                              });
                        },
                        icon: Icon(
                          Icons.image,
                          size: 18,
                        ))
                    : Container(),
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
                        items: const [
                          DropdownMenuItem<String>(
                              alignment: Alignment.center,
                              value: "Transactions",
                              child: Text(
                                "Transactions",
                                style: TextStyle(color: Colors.lightBlueAccent),
                              )),
                          DropdownMenuItem<String>(
                              alignment: Alignment.center,
                              value: "Subscription",
                              child: Text(
                                "Subscription",
                                style: TextStyle(color: Colors.lightBlueAccent),
                              )),
                        ],
                        value: data.categoryFilter,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              data.categoryFilter = value;
                              recalculate(regenerateRows: true);
                            }
                          });
                        }));
              },
              body: SingleChildScrollView(
                  child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(32),
                  4: FixedColumnWidth(32),
                  6: FixedColumnWidth(32),
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
                            textAlign: TextAlign.center,
                          ),
                        )),
                        TableCell(
                            child: Text(
                          "Type",
                          style: label,
                          textAlign: TextAlign.center,
                        )),
                        TableCell(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: Text(
                            "Memo",
                            style: label,
                            textAlign: TextAlign.center,
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
              isExpanded: expanded)
        ]);
  }
}
