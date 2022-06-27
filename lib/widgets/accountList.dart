// ignore_for_file: no_logic_in_create_state

import 'package:budgies_budgets/helpers/backendRequests.dart';
import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';

class AccountList extends StatefulWidget {
  final FinancialData data;
  final Function recalculate;

  const AccountList({Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  AccountListState createState() =>
      AccountListState(data: data, recalculate: recalculate);
}

class AccountListState extends State<AccountList> {
  final FinancialData data;
  final Function recalculate;
  bool expanded = false;
  List<TableRow> rows = [];
  final TextStyle label = const TextStyle(color: Colors.amber, fontSize: 12);
  final TextStyle stringValue = const TextStyle(color: Colors.lightBlueAccent);
  TextEditingController balanceController = TextEditingController();
  bool isGiftcard = false;

  AccountListState({required this.data, required this.recalculate});

  @override
  void initState() {
    super.initState();
    generateRows();
  }

  void generateRows() {
    setState(() {
      rows = [];
      int count = 0;
      data.sortAccounts();
      for (Account a in data.accounts.where((acct) =>
          acct.user == data.currentUser &&
          (data.currentAccount == acct.name || data.currentAccount == "All"))) {
        TextStyle numValue = TextStyle(
            color:
                (a.balance >= 0) ? Colors.lightGreenAccent : Colors.redAccent);
        rows.add(TableRow(
            decoration: BoxDecoration(
                color: (count % 2 == 0)
                    ? const Color.fromARGB(255, 66, 66, 66)
                    : const Color.fromARGB(255, 80, 80, 80)),
            children: [
              TableCell(
                child: Center(child: Text(a.name, style: stringValue)),
              ),
              TableCell(
                child: Center(
                    child: Text("\$ " + a.balance.toStringAsFixed(2),
                        style: numValue)),
              ),
              TableCell(
                  child: Center(
                      child: (a.isGiftcard)
                          ? const Icon(Icons.card_giftcard, size: 18)
                          : Container())),
              TableCell(
                child: IconButton(
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
                                          a.balance = double.parse(
                                              balanceController.text);
                                          a.isGiftcard = isGiftcard;
                                          modifyAccount(a);
                                          isGiftcard = false;
                                          balanceController.text = "0.00";
                                          recalculate(updateAccountList: true);
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
                                                    const TextInputType
                                                            .numberWithOptions(
                                                        signed: true,
                                                        decimal: true),
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
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                    )),
              )
            ]));
        count++;
      }
    });
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
            isExpanded: expanded,
            headerBuilder: (BuildContext context, bool expanded) {
              return const ListTile(
                  title: Center(child: Text("            Account Details")));
            },
            body: SingleChildScrollView(
                child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(),
              columnWidths: const {3: FixedColumnWidth(32)},
              children: <TableRow>[
                    TableRow(children: [
                      TableCell(
                        child: Center(
                            child: Text(
                          "Name",
                          style: label,
                        )),
                      ),
                      TableCell(
                        child: Center(child: Text("Balance", style: label)),
                      ),
                      TableCell(
                        child: Center(child: Text("Giftcard", style: label)),
                      ),
                      const TableCell(
                        child: Center(child: Text("")),
                      )
                    ])
                  ] +
                  rows,
            )))
      ],
    );
  }
}
