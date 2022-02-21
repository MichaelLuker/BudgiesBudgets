// All the parts for filling out details for a new transaction
import 'dart:developer';
import 'dart:io';

import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:image_picker/image_picker.dart';

class editTransaction extends StatefulWidget {
  final Transaction transaction;
  final Function recalculate;
  final FinancialData data;
  const editTransaction(
      {Key? key,
      required this.transaction,
      required this.recalculate,
      required this.data})
      : super(key: key);

  @override
  _editTransactionState createState() => _editTransactionState(
      transaction: transaction, recalculate: recalculate, data: data);
}

class _editTransactionState extends State<editTransaction> {
  final Transaction transaction;
  final Function recalculate;
  final FinancialData data;
  _editTransactionState(
      {required this.transaction,
      required this.recalculate,
      required this.data});
  TextEditingController amountController = TextEditingController();
  TextEditingController memoController = TextEditingController();
  DateTime newDate = DateTime.now();
  bool confirmDelete = false;
  Image? transactionImage;

  @override
  void initState() {
    super.initState();
    amountController.text = transaction.strAmount();
    memoController.text = transaction.memo;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        titlePadding: const EdgeInsets.all(8),
        contentPadding: const EdgeInsets.all(8),
        title: Container(
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide())),
            child: const Center(child: Text("Edit Transaction Details"))),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Confirm Deletion"),
                        content: Text(
                            "Please confirm that the transaction should be deleted...\n\n${transaction.toString()}"),
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
                                setState(() {
                                  confirmDelete = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Confirm",
                                style:
                                    TextStyle(color: Colors.lightGreenAccent),
                              ))
                        ],
                      );
                    }).then((e) {
                  if (confirmDelete) {
                    deleteTransaction(transaction);
                    data.allTransactions.remove(transaction);
                    recalculate(regenerateRows: true);
                    setState(() {
                      confirmDelete = false;
                    });
                    Navigator.of(context).pop();
                  }
                });
              },
              icon: const Icon(Icons.delete, size: 18)),
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Enter New Date"),
                        content: SizedBox(
                          width: 300,
                          height: 300,
                          child: CalendarDatePicker(
                              initialDate: data.endDate,
                              firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                              lastDate: DateTime.now(),
                              onDateChanged: (e) {
                                setState(() {
                                  newDate = e;
                                });
                              }),
                        ),
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
                                setState(() {
                                  confirmDelete = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "Confirm",
                                style:
                                    TextStyle(color: Colors.lightGreenAccent),
                              ))
                        ],
                      );
                    }).then((e) {
                  Transaction newTransaction = Transaction.withValues(
                      user: transaction.user,
                      date: newDate,
                      category: transaction.category,
                      account: transaction.account,
                      amount: transaction.amount,
                      memo: transaction.memo);

                  setState(() {
                    data.allTransactions.add(newTransaction);
                    confirmDelete = false;
                  });
                  recalculate(regenerateRows: true);
                  Navigator.of(context).pop();
                });
              },
              icon: const Icon(
                Icons.copy,
                size: 18,
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
                  transaction.amount = double.parse(amountController.text);
                } catch (e) {
                  transaction.amount = transaction.amount;
                }
                transaction.memo = memoController.text;
                if (transactionImage != null) {
                  transaction.hasMemoImage = true;
                  transaction.memoImageWidget =
                      InteractiveViewer(child: transactionImage!);
                  setState(() {
                    transactionImage = null;
                  });
                }
                modifyTransaction(transaction);
                recalculate(regenerateRows: true);
                Navigator.of(context).pop();
              },
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.lightGreenAccent),
              ))
        ],
        content: SingleChildScrollView(
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
                    formatDate(transaction.date) + "  ",
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
                                    DateTime.fromMillisecondsSinceEpoch(0),
                                lastDate:
                                    DateTime.now().add(Duration(days: 365)))
                            .then((value) {
                          setState(() {
                            if (value != null) {
                              transaction.date = value;
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
                        value: transaction.category,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              transaction.category = value;
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
                        items: data.getUserAccounts(all: false),
                        value: transaction.account,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              transaction.account = value;
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
                      style: const TextStyle(color: Colors.lightBlueAccent),
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
                      keyboardType: TextInputType.number,
                      controller: memoController,
                      style: const TextStyle(color: Colors.lightBlueAccent),
                    )),
              ],
            ),
            // Optional image associated with a transaction
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(flex: 0, child: Text("Image:      ")),
                Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        (transaction.hasMemoImage || transactionImage != null)
                            ? Expanded(
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        transactionImage = null;
                                        transaction.hasMemoImage = false;
                                      });
                                    },
                                    icon: Icon(Icons.delete)),
                              )
                            : Container(),
                        Expanded(
                          child: IconButton(
                              onPressed: () async {
                                FilePickerResult? file =
                                    await FilePicker.platform.pickFiles();
                                if (file != null) {
                                  String filePath =
                                      file.files[0].path.toString();
                                  transactionImage = Image.file(File(filePath));
                                }
                              },
                              icon: Icon(
                                Icons.upload_file,
                              )),
                        ),
                        (Platform.isAndroid || Platform.isIOS)
                            ? Expanded(
                                child: IconButton(
                                    onPressed: () async {
                                      ImagePicker imagePicker = ImagePicker();
                                      XFile? image =
                                          await imagePicker.pickImage(
                                              source: ImageSource.camera);
                                      if (image != null) {
                                        setState(() {
                                          transactionImage =
                                              Image.file(File(image.path));
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      Icons.add_a_photo,
                                    )),
                              )
                            : Container()
                      ],
                    )),
              ],
            ),
          ],
        )),
      );
    });
  }
}
