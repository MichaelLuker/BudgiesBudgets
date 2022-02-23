// ignore_for_file: no_logic_in_create_state, file_names

import 'package:budgies_budgets/helpers/backendRequests.dart';
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
      AccountSelectState(data: data, recalculate: recalculate);
}

class AccountSelectState extends State<AccountSelect> {
  final FinancialData data;
  final Function recalculate;
  AccountSelectState({required this.data, required this.recalculate});

  TextEditingController nameController = TextEditingController();
  TextEditingController balanceController = TextEditingController();
  String selectedAccount = "All";
  List<DropdownMenuItem<String>> accounts = [];
  bool isGiftcard = false;
  bool confirmDelete = false;

  void updateAccountDropdown() {
    setState(() {
      selectedAccount = data.currentAccount;
      accounts = data.getUserAccounts();
    });
  }

  @override
  void initState() {
    super.initState();
    updateAccountDropdown();
  }

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
                        items: accounts,
                        value: selectedAccount,
                        onChanged: (value) {
                          setState(() {
                            if (value != null) {
                              data.currentAccount = value;
                              selectedAccount = value;
                              recalculate(
                                  regenerateRows: true,
                                  updateAccountList: true,
                                  updateGraphs: true);
                            }
                          });
                        })),
                // For creating a new account
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
                                  title: const Text("New Account"),
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
                                          Account newAcct = Account.withValues(
                                              user: data.currentUser,
                                              name: nameController.text,
                                              balance: double.parse(
                                                  balanceController.text),
                                              isGiftcard: isGiftcard);
                                          createNewAccount(newAcct);
                                          setState(() {
                                            data.accounts.add(newAcct);
                                            isGiftcard = false;
                                            nameController.text = "";
                                            balanceController.text = "0.00";
                                            recalculate(
                                                updateAccountDropdowns: true,
                                                updateAccountList: true,
                                                updateGraphs: true);
                                          });
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
                                              flex: 0,
                                              child: Text("Name:      ")),
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
                                              child: Text("Giftcard:  ")),
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
                          });
                    },
                    icon: const Icon(Icons.account_balance)),
                // For deleting an account
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Confirm Account Deletion"),
                              content: Text(
                                  "Please confirm that ${data.currentAccount} and all associated transactions should be deleted..."),
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
                            for (Transaction t in data.allTransactions) {
                              if (t.account == data.currentAccount) {
                                deleteTransaction(t);
                              }
                            }
                            data.allTransactions.removeWhere(
                                (t) => t.account == data.currentAccount);
                            // Then delete the account
                            deleteAccount(data.accounts
                                .where(
                                    (acct) => acct.name == data.currentAccount)
                                .first);
                            data.accounts.removeWhere((element) =>
                                element.name == data.currentAccount);
                            data.currentAccount = "All";
                            recalculate(
                                regenerateRows: true,
                                updateAccountDropdowns: true,
                                updateAccountList: true,
                                updateGraphs: true);
                            confirmDelete = false;
                          }
                        });
                      });
                    },
                    icon: const Icon(Icons.dangerous))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
