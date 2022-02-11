// Objects to be able to store all the data for the different widgets to interact with
// ignore_for_file: constant_identifier_names
import 'package:budgies_budgets/helpers/functions.dart';
import 'package:flutter/material.dart';

// Different categories that a transaction can be
enum Category {
  Rent,
  Transportation,
  Food,
  Utilities,
  Insurance,
  Medical,
  Savings,
  Personal,
  Entertainment,
  Miscellaneous
}

// Different accounts that transactions can pull from
enum Account { Checking, Savings, Visa, Giftcard }

List<String> GiftAccounts = [];

class Transaction {
  int id = -1;
  DateTime date = DateTime.now();
  Category category = Category.Personal;
  Account account = Account.Visa;
  double amount = 0.0;
  String memo = "";

  Transaction();
  Transaction.withValues(
      {required this.id,
      required this.date,
      required this.category,
      required this.account,
      required this.amount,
      required this.memo});

  // Round the double to 2 decimals and return it as a string
  String strAmount() {
    return "\$ " + amount.toStringAsFixed(2);
  }

  @override
  String toString() {
    return "Date: ${formatDate(date)} | Category: ${category.toString().split(".")[1]} | Account: ${account.toString().split(".")[1]} | Amount: ${strAmount()} | Memo: $memo\n";
  }
}

class FinancialData {
  late DateTime startDate;
  late DateTime endDate;
  Map<Account, double> accounts = {};
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];

  // Sort the filtered list of transactions
  //   The beginning of the list will be the most recent(end date), the end of the list will
  //   be the oldest date in the range (start date)
  void sort() {
    // Start with an empty list
    filteredTransactions = [];

    // For each transaction available, check if it's in the date range
    for (Transaction t in allTransactions) {
      // Allow it to be on the actual day of the start or end
      if (t.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          t.date.isBefore(endDate.add(Duration(days: 1)))) {
        filteredTransactions.add(t);
      }
    }

    // Once all the transactions have been filtered to the date range, sort by the date
    filteredTransactions
        .sort((Transaction a, Transaction b) => b.date.compareTo(a.date));

    // Finally go through and set the ID on each transaction
    for (int i = 0; i < filteredTransactions.length; i++) {
      filteredTransactions[i].id = i;
    }
  }

  @override
  String toString() {
    return "  startDate: ${formatDate(startDate)}\n  endDate: ${formatDate(endDate)}\n  accounts: ${accounts.toString()}\n  transactions: \n  ${filteredTransactions.toString()}";
  }
}
