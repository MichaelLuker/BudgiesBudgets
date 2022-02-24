// ignore_for_file: no_logic_in_create_state, file_names

import 'package:budgies_budgets/helpers/backgroundData.dart';
import 'package:flutter/material.dart';

// Lets you select the month / year / date range to use
class MonthSelect extends StatefulWidget {
  // Save the current start and end dates
  final FinancialData data;
  final Function recalculate;

  // Set dates on creation
  const MonthSelect({Key? key, required this.data, required this.recalculate})
      : super(key: key);

  @override
  State<MonthSelect> createState() =>
      _MonthSelectState(data: data, recalculate: recalculate);
}

class _MonthSelectState extends State<MonthSelect> {
  final FinancialData data;
  final Function recalculate;
  _MonthSelectState({required this.data, required this.recalculate});

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
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: DateTimeRange(
                              start: data.startDate, end: data.endDate))
                      .then((value) {
                    // If the save button was clicked update the values, otherwise do nothing
                    if (value != null) {
                      setState(() {
                        data.startDate = value.start;
                        data.endDate = value.end;
                        recalculate(
                            regenerateRows: true,
                            updateGraphs: true,
                            sync: true);
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
