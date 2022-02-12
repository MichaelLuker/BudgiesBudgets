// All the parts for filling out details for a new transaction
import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/helpers/functions.dart';
import 'package:grizzly_io/io_loader.dart';

class newTransaction extends StatefulWidget {
  final FinancialData data;
  final Function updateList;
  const newTransaction({Key? key, required this.data, required this.updateList})
      : super(key: key);

  @override
  _newTransactionState createState() =>
      _newTransactionState(data: data, updateList: updateList);
}

class _newTransactionState extends State<newTransaction> {
  final FinancialData data;
  final Function updateList;
  _newTransactionState({required this.data, required this.updateList});
  TextEditingController amountController = TextEditingController();
  TextEditingController memoController = TextEditingController();
  Transaction newTransaction = Transaction();
  bool bulkImport = false;
  bool dragging = false;

  @override
  void initState() {
    super.initState();
    amountController.text = "0.00";
  }

  @override
  Widget build(BuildContext context) {
    Transaction newTransaction = Transaction();
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        titlePadding: const EdgeInsets.all(8),
        contentPadding: const EdgeInsets.all(8),
        title: Container(
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide())),
            child: Center(
                child: bulkImport
                    ? Text("Bulk Transaction Import")
                    : Text("New Transaction Details"))),
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  bulkImport = !bulkImport;
                });
              },
              child: const Text(
                "Bulk Import",
                style: TextStyle(color: Colors.amberAccent),
              )),
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
                try {
                  newTransaction.amount = double.parse(amountController.text);
                } catch (e) {
                  newTransaction.amount = 0.0;
                }
                newTransaction.memo = memoController.text;
                newTransaction.id = data.allTransactions.length;
                newTransaction.user = data.currentUser;
                data.allTransactions.add(newTransaction);
                updateList();
                Navigator.of(context).pop();
              },
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.lightGreenAccent),
              ))
        ],
        content: (!bulkImport)
            ? SingleChildScrollView(
                child: ListBody(
                children: [
                  // First enter the date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(flex: 0, child: Text("Date:          ")),
                      Expanded(
                        flex: 3,
                        child: Text(
                          formatDate(newTransaction.date) + "  ",
                          style: const TextStyle(color: Colors.lightBlueAccent),
                        ),
                      ),
                      Flexible(
                          flex: 0,
                          child: IconButton(
                            iconSize: 18.0,
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate:
                                          DateTime.fromMillisecondsSinceEpoch(
                                              0),
                                      lastDate: DateTime.now())
                                  .then((value) {
                                setState(() {
                                  if (value != null) {
                                    newTransaction.date = value;
                                  }
                                });
                              });
                            },
                          ))
                    ],
                  ),
                  // Then the category as a dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(flex: 0, child: Text("Category:   ")),
                      Expanded(
                          flex: 3,
                          child: DropdownButton<Category>(
                              isExpanded: true,
                              items: Category.values.map((e) {
                                return DropdownMenuItem<Category>(
                                    value: e,
                                    child: Text(
                                      e.toString().split(".")[1],
                                      style: const TextStyle(
                                          color: Colors.lightBlueAccent),
                                    ));
                              }).toList(),
                              value: newTransaction.category,
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    newTransaction.category = value;
                                  }
                                });
                              })),
                    ],
                  ),
                  // Then the account as a dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(flex: 0, child: Text("Account:    ")),
                      Expanded(
                          flex: 3,
                          child: DropdownButton<String>(
                              isExpanded: true,
                              items: data.accounts.map((e) {
                                return DropdownMenuItem<String>(
                                    value: e.name,
                                    child: Text(
                                      e.name,
                                      style: const TextStyle(
                                          color: Colors.lightBlueAccent),
                                    ));
                              }).toList(),
                              value: newTransaction.account,
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    newTransaction.account = value;
                                  }
                                });
                              })),
                    ],
                  ),
                  // Then the amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(flex: 0, child: Text("Amount:  \$ ")),
                      Expanded(
                          flex: 3,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: amountController,
                            style:
                                const TextStyle(color: Colors.lightBlueAccent),
                          )),
                    ],
                  ),
                  // Finally the memo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(flex: 0, child: Text("Memo:        ")),
                      Expanded(
                          flex: 3,
                          child: TextField(
                            keyboardType: TextInputType.text,
                            controller: memoController,
                            style:
                                const TextStyle(color: Colors.lightBlueAccent),
                          )),
                    ],
                  ),
                ],
              ))
            : SizedBox(
                width: 200,
                height: 232,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 114, 114, 114)),
                    child: IconButton(
                        onPressed: () async {
                          FilePickerResult? file =
                              await FilePicker.platform.pickFiles();
                          if (file != null) {
                            String filePath = file.files[0].path.toString();
                            log(filePath);
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
                                log(t.toString());
                                data.allTransactions.add(t);
                              }
                              log(data.allTransactions.toString());
                              updateList();
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(
                          Icons.note_add,
                          color: Colors.black,
                          size: 64,
                        )),
                  ),
                )),
      );
    });
  }
}
