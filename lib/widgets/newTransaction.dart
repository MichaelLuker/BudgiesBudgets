// All the parts for filling out details for a new transaction
// ignore_for_file: file_names, camel_case_types, no_logic_in_create_state

import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:grizzly_io/io_loader.dart';
import 'dart:io' show File, Platform;

import 'package:image_picker/image_picker.dart';

class newTransaction extends StatefulWidget {
  final FinancialData data;
  final Function recalculate;
  const newTransaction(
      {Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  _newTransactionState createState() =>
      _newTransactionState(data: data, recalculate: recalculate);
}

class _newTransactionState extends State<newTransaction> {
  final FinancialData data;
  final Function recalculate;
  _newTransactionState({required this.data, required this.recalculate});
  TextEditingController amountController = TextEditingController();
  TextEditingController memoController = TextEditingController();

  bool bulkImport = false;
  bool dragging = false;
  Image? transactionImage;
  String? imagePath;
  late List<DropdownMenuItem<String>> userAccounts;

  @override
  Widget build(BuildContext context) {
    Transaction newTransaction = Transaction();
    setState(() {
      amountController.text = "0.00";
      newTransaction.account = data.accounts
          .firstWhere((acct) => acct.user == data.currentUser)
          .name;
      userAccounts = data.getUserAccounts(all: false);
    });
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
          titlePadding: const EdgeInsets.all(8),
          contentPadding: const EdgeInsets.all(8),
          title: Container(
              decoration:
                  const BoxDecoration(border: Border(bottom: BorderSide())),
              child: Center(
                  child: bulkImport
                      ? const Text("Bulk Transaction Import")
                      : const Text("New Transaction Details"))),
          actions: [
            TextButton(
                onPressed: () async {
                  setState(() {
                    bulkImport = !bulkImport;
                  });
                  FilePickerResult? file = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png']);
                  if (file != null) {
                    String filePath = file.files[0].path.toString();
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
                        t.guid = generateGUID(t);
                        writeNewTransaction(t);
                        data.allTransactions.add(t);
                        recalculate(t: t, action: "add");
                      }
                      recalculate(
                          regenerateRows: true,
                          updateAccountList: true,
                          updateGraphs: true);
                    });
                    Navigator.of(context).pop();
                  }
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
                  newTransaction.user = data.currentUser;
                  if (transactionImage != null) {
                    newTransaction.hasMemoImage = true;
                    newTransaction.memoImagePath = imagePath;
                    newTransaction.memoImageWidget =
                        InteractiveViewer(child: transactionImage!);
                    setState(() {
                      transactionImage = null;
                    });
                  }
                  newTransaction.guid = generateGUID(newTransaction);
                  // Adding the transaction locally
                  data.allTransactions.add(newTransaction);
                  // Write the new transaction to the backend
                  writeNewTransaction(newTransaction);
                  recalculate(
                      t: newTransaction,
                      action: "add",
                      regenerateRows: true,
                      updateAccountList: true,
                      updateGraphs: true);
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
                                      DateTime.fromMillisecondsSinceEpoch(0),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)))
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
                          items: userAccounts,
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
                        keyboardType: TextInputType.text,
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
                          Expanded(
                            child: IconButton(
                                onPressed: () async {
                                  FilePickerResult? file =
                                      await FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                        'jpg',
                                        'jpeg',
                                        'png'
                                      ]);
                                  if (file != null) {
                                    String filePath =
                                        file.files[0].path.toString();
                                    imagePath = filePath;
                                    transactionImage =
                                        Image.file(File(filePath));
                                  }
                                },
                                icon: const Icon(
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
                                                source: ImageSource.camera,
                                                imageQuality: 75);
                                        if (image != null) {
                                          setState(() {
                                            imagePath = image.path;
                                            transactionImage =
                                                Image.file(File(image.path));
                                          });
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.add_a_photo,
                                      )),
                                )
                              : Container()
                        ],
                      )),
                ],
              ),
            ],
          )));
    });
  }
}
