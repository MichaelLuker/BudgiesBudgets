// ignore_for_file: no_logic_in_create_state

import 'dart:developer';

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';

// Lets you select the month / year / date range to use
class AccountSelect extends StatefulWidget {
  // Save the current start and end dates
  final FinancialData data;
  final Function recalculate;

  // Set dates on creation
  const AccountSelect({Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  State<AccountSelect> createState() =>
      _AccountSelect(data: data, recalculate: recalculate);
}

class _AccountSelect extends State<AccountSelect> {
  final FinancialData data;
  final Function recalculate;
  _AccountSelect({required this.data, required this.recalculate});

  TextEditingController nameController = TextEditingController();
  TextEditingController balanceController = TextEditingController();
  bool isGiftcard = false;
  bool confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add a lower border to separate this from the other widgets
      decoration: const BoxDecoration(border: Border(bottom: BorderSide())),
      // Put everything in a single row, this is a fairly simple widget
      child: Row(
        // Center everything
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User selection drop down
          Expanded(
            flex: 9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(flex: 1, child: Text("Acct:  ")),
                Expanded(
                    flex: 3,
                    child: DropdownButton<String>(
                        isExpanded: true,
                        items: <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                  value: "All",
                                  child: Text(
                                    "All",
                                    style: const TextStyle(
                                        color: Colors.lightBlueAccent),
                                  ))
                            ] +
                            data.accounts.map((e) {
                              return DropdownMenuItem<String>(
                                  value: e.name,
                                  child: Text(
                                    e.name,
                                    style: const TextStyle(
                                        color: Colors.lightBlueAccent),
                                  ));
                            }).toList(),
                        value: data.currentAccount,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              data.currentAccount = value;
                              recalculate(regenerateRows: true);
                            }
                          });
                        })),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                  titlePadding: const EdgeInsets.all(8),
                                  contentPadding: const EdgeInsets.all(8),
                                  title: Container(child: Text("New Account")),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        )),
                                    TextButton(
                                        onPressed: () {
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
                                      // Account name
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Flexible(
                                              flex: 0, child: Text("Name:   ")),
                                          Expanded(
                                              flex: 3,
                                              child: TextField(
                                                keyboardType:
                                                    TextInputType.text,
                                                controller: nameController,
                                                style: const TextStyle(
                                                    color:
                                                        Colors.lightBlueAccent),
                                              )),
                                        ],
                                      ),
                                      // Account balance
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Flexible(
                                              flex: 0,
                                              child: Text("Balance:   ")),
                                          Expanded(
                                              flex: 3,
                                              child: TextField(
                                                keyboardType:
                                                    TextInputType.number,
                                                controller: balanceController,
                                                style: const TextStyle(
                                                    color:
                                                        Colors.lightBlueAccent),
                                              )),
                                        ],
                                      ),
                                      // Giftcard Status
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Flexible(
                                              flex: 0,
                                              child: Text("Giftcard:   ")),
                                          Expanded(
                                              flex: 3,
                                              child: Checkbox(
                                                  value: isGiftcard,
                                                  onChanged: (_) {
                                                    setState(() {
                                                      isGiftcard = _!;
                                                    });
                                                  })),
                                        ],
                                      ),
                                    ],
                                  )));
                            });
                          }).then((e) {
                        setState(() {
                          data.accounts.add(Account.withValues(
                              name: nameController.text,
                              balance: 0,
                              isGiftcard: isGiftcard));
                          data.sortAccounts();
                          nameController.text = "";
                          balanceController.text = "";
                          isGiftcard = false;
                        });
                      });
                    },
                    icon: Icon(Icons.account_balance)),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Confirm Account Deletion"),
                              content: Text(
                                  "Please confirm that ${data.currentAccount} should be deleted..."),
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
                                      style: TextStyle(
                                          color: Colors.lightGreenAccent),
                                    ))
                              ],
                            );
                          }).then((e) {
                        setState(() {
                          if (data.accounts.length > 1 && confirmDelete) {
                            // Delete the transactions for the account
                            data.allTransactions.removeWhere(
                                (t) => t.account == data.currentAccount);
                            // Then delete the account
                            data.accounts.removeWhere((element) =>
                                element.name == data.currentAccount);
                            data.currentAccount = data.accounts[0].name;
                            recalculate(regenerateRows: true);
                            confirmDelete = false;
                          }
                        });
                      });
                    },
                    icon: Icon(Icons.dangerous))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
