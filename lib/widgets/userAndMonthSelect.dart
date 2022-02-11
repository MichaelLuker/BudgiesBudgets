// ignore_for_file: no_logic_in_create_state

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:budgies_budgets/helpers/functions.dart';
import 'package:flutter/material.dart';

// Lets you select the month / year / date range to use
class UserAndMonthSelect extends StatefulWidget {
  // Save the current start and end dates
  final FinancialData data;
  final Function recalculate;

  // Set dates on creation
  const UserAndMonthSelect(
      {Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  State<UserAndMonthSelect> createState() =>
      _UserAndMonthSelect(data: data, recalculate: recalculate);
}

class _UserAndMonthSelect extends State<UserAndMonthSelect> {
  final FinancialData data;
  final Function recalculate;
  _UserAndMonthSelect({required this.data, required this.recalculate});

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
                              recalculate(regenerateRows: true);
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
                                title: Container(child: Text("New User")),
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
                                              keyboardType:
                                                  TextInputType.number,
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
                    icon: Icon(Icons.person_add)),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Confirm User Deletion"),
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
                    icon: Icon(Icons.person_remove))
              ],
            ),
          ),
          // Expand the two date widgets more than the icon button, use the function to fill in the date strings
          Expanded(
              flex: 9,
              child:
                  Center(child: Text("Start: ${formatDate(data.startDate)}"))),
          Expanded(
              flex: 9,
              child: Center(child: Text("End: ${formatDate(data.endDate)}"))),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: IconButton(
                onPressed: () {
                  // Show any day from Epoch until now, have the current range selected
                  showDateRangePicker(
                          context: context,
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          lastDate: DateTime.now(),
                          initialDateRange: DateTimeRange(
                              start: data.startDate, end: data.endDate))
                      .then((value) {
                    // If the save button was clicked update the values, otherwise do nothing
                    if (value != null) {
                      setState(() {
                        data.startDate = value.start;
                        data.endDate = value.end;
                        recalculate(regenerateRows: true);
                      });
                    }
                  });
                },
                icon: const Icon(
                  Icons.calendar_today_rounded,
                )),
          )
        ],
      ),
    );
  }
}
