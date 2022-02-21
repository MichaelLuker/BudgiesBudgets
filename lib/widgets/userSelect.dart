// ignore_for_file: no_logic_in_create_state, file_names

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';

// Lets you select the month / year / date range to use
class UserSelect extends StatefulWidget {
  // Save the current start and end dates
  final FinancialData data;
  final Function recalculate;

  // Set dates on creation
  const UserSelect({Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  State<UserSelect> createState() =>
      _UserSelect(data: data, recalculate: recalculate);
}

class _UserSelect extends State<UserSelect> {
  final FinancialData data;
  final Function recalculate;
  _UserSelect({required this.data, required this.recalculate});

  TextEditingController userController = TextEditingController();
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
                const Flexible(flex: 1, child: Text("User:   ")),
                Expanded(
                    flex: 3,
                    child: DropdownButton<String>(
                        isExpanded: true,
                        items: data.users.map((e) {
                          return DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ));
                        }).toList(),
                        value: data.currentUser,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              data.currentUser = value;
                              data.currentAccount = "All";
                              data.categoryFilter = "Transactions";
                              recalculate(
                                  regenerateRows: true,
                                  updateAccountDropdowns: true);
                            }
                          });
                        })),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                                titlePadding: const EdgeInsets.all(8),
                                contentPadding: const EdgeInsets.all(8),
                                title: const Text("New User"),
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
                                    // Finally the memo
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Flexible(
                                            flex: 0,
                                            child: Text("Username:        ")),
                                        Expanded(
                                            flex: 3,
                                            child: TextField(
                                              keyboardType: TextInputType.text,
                                              controller: userController,
                                              style: const TextStyle(
                                                  color:
                                                      Colors.lightBlueAccent),
                                            )),
                                      ],
                                    ),
                                  ],
                                )));
                          }).then((e) {
                        setState(() {
                          data.users.add(userController.text);
                          data.currentUser = userController.text;
                          userController.text = "";
                          recalculate(regenerateRows: true);
                        });
                      });
                    },
                    icon: const Icon(Icons.person_add)),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Confirm User Deletion"),
                              content: Text(
                                  "Please confirm that user ${data.currentUser} should be deleted..."),
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
                          if (data.users.length > 1 && confirmDelete) {
                            // Delete the transactions for the user
                            data.allTransactions
                                .removeWhere((t) => t.user == data.currentUser);
                            // Then delete the user
                            data.users.remove(data.currentUser);
                            data.currentUser = data.users[0];
                            recalculate(regenerateRows: true);
                            confirmDelete = false;
                          }
                        });
                      });
                    },
                    icon: const Icon(Icons.person_remove))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
