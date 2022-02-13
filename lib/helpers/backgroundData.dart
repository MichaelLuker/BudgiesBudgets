// Objects to be able to store all the data for the different widgets to interact with
// ignore_for_file: constant_identifier_names
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:svg_icon/svg_icon.dart';

// Different categories that a transaction can be
enum Category {
  Housing, // Icons.home
  Transportation, // Icons.commute
  Food, // Icons.store or Icons.shopping_bag or Icons.shopping_basket
  Utilities, // Icons.outlet
  Insurance, // Icons.assignment
  Medical, // Icons.favorite
  Savings, // Icons.savings
  Personal, // Icons.face or
  Entertainment, // Icons.extension or icons.rocket_launch or icons.rowing
  Miscellaneous, // Icons.book
  Income, // Icons.paid or Icons.work
  Transfer, // Icons.sync_alt
  Giftcard, // Icons.card_giftcard
  Fee, // Icons.paid
  Subscription // Icons.autorenew
}

Widget categoryToIcon(Category c, double size) {
  switch (c) {
    case Category.Housing:
      return Icon(Icons.home, size: size);
    case Category.Transportation:
      return Icon(Icons.commute);
    case Category.Food:
      return Icon(Icons.shopping_cart, size: size);
    case Category.Utilities:
      return Icon(Icons.outlet, size: size);
    case Category.Insurance:
      return Icon(Icons.assignment, size: size);
    case Category.Medical:
      return Icon(Icons.favorite, size: size);
    case Category.Savings:
      return Icon(Icons.savings, size: size);
    case Category.Personal:
      return Icon(Icons.face, size: size);
    case Category.Entertainment:
      return SvgIcon("icons/rocket_launch_white_24dp.svg");
    case Category.Miscellaneous:
      return Icon(Icons.book, size: size);
    case Category.Income:
      return Icon(Icons.paid, size: size);
    case Category.Transfer:
      return Icon(Icons.sync_alt, size: size);
    case Category.Giftcard:
      return Icon(Icons.card_giftcard, size: size);
    case Category.Fee:
      return Icon(Icons.paid, size: size);
    case Category.Subscription:
      return Icon(Icons.autorenew, size: size);
    default:
      return Icon(Icons.home, size: size);
  }
}

Category categoryFromString(String s) {
  switch (s) {
    case "Housing":
      return Category.Housing;
    case "Transportation":
      return Category.Transportation;
    case "Food":
      return Category.Food;
    case "Utilities":
      return Category.Utilities;
    case "Insurance":
      return Category.Insurance;
    case "Medical":
      return Category.Medical;
    case "Savings":
      return Category.Savings;
    case "Personal":
      return Category.Personal;
    case "Entertainment":
      return Category.Entertainment;
    case "Miscellaneous":
      return Category.Miscellaneous;
    case "Income":
      return Category.Income;
    case "Transfer":
      return Category.Transfer;
    case "Giftcard":
      return Category.Giftcard;
    case "Fee":
      return Category.Fee;
    case "Subscription":
      return Category.Subscription;
    default:
      return Category.Personal;
  }
}

class Account {
  String name = "Visa";
  double balance = 0.00;
  bool isGiftcard = false;
  Account();
  Account.withValues({
    required this.name,
    required this.balance,
    required this.isGiftcard,
  });
}

class Transaction {
  int id = -1;
  DateTime date = DateTime.now();
  Category category = Category.Personal;
  String account = "Visa";
  double amount = 0.0;
  String memo = "";
  String user = "";
  Image? memoImage;

  Transaction();
  Transaction.withValues(
      {required this.user,
      required this.date,
      required this.category,
      required this.account,
      required this.amount,
      required this.memo});

  // Round the double to 2 decimals and return it as a string
  String strAmount() {
    return amount.toStringAsFixed(2);
  }

  @override
  String toString() {
    return "User: $user | Date: ${formatDate(date)} | Category: ${category.toString().split(".")[1]} | Account: $account | Amount: ${strAmount()} | Memo: $memo\n";
  }
}

String monthString(int n) {
  switch (n) {
    case 1:
      return "Jan";
    case 2:
      return "Feb";
    case 3:
      return "Mar";
    case 4:
      return "Apr";
    case 5:
      return "May";
    case 6:
      return "Jun";
    case 7:
      return "Jul";
    case 8:
      return "Aug";
    case 9:
      return "Sep";
    case 10:
      return "Oct";
    case 11:
      return "Nov";
    case 12:
      return "Dec";
    default:
      return "Unknown";
  }
}

// Returns a string of the date time in the format MMM DD YYYY like Feb 09 2022
String formatDate(DateTime d) {
  return "${monthString(d.month)} ${(d.day < 10) ? "0" + d.day.toString() : d.day} ${d.year}";
}

class FinancialData {
  late DateTime startDate;
  late DateTime endDate;
  List<Account> accounts = [
    Account.withValues(name: "Checking", balance: 0.00, isGiftcard: false),
    Account.withValues(name: "Savings", balance: 0.00, isGiftcard: false),
    Account.withValues(name: "Visa", balance: 0.00, isGiftcard: false),
  ];
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  List<String> users = [];
  String currentUser = "";
  String currentAccount = "All";
  String categoryFilter = "Transactions";

  // Sorts the non-giftcard accounts by name and the giftcard accounts last
  void sortAccounts() {
    List<Account> tempNormal = [];
    List<Account> tempGiftcards = [];

    // For each account throw it in the appropriate bucket
    for (Account a in accounts) {
      if (a.isGiftcard) {
        tempGiftcards.add(a);
      } else {
        tempNormal.add(a);
      }
    }

    // Sort the individual lists
    tempNormal.sort((Account a, Account b) => a.name.compareTo(b.name));
    tempGiftcards.sort((Account a, Account b) => a.name.compareTo(b.name));

    // Combine lists back
    accounts = tempNormal + tempGiftcards;
  }

  // Sort the filtered list of transactions
  //   The beginning of the list will be the most recent(end date), the end of the list will
  //   be the oldest date in the range (start date)
  void sortTransactions() {
    // Start with an empty list
    filteredTransactions = [];

    // For each transaction available, check if it's in the date range
    for (Transaction t in allTransactions) {
      // Allow it to be on the actual day of the start or end
      if (t.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          t.date.isBefore(endDate.add(Duration(days: 1))) &&
          t.user == currentUser &&
          (t.account == currentAccount || currentAccount == "All") &&
          (t.category == categoryFromString(categoryFilter) ||
              categoryFilter == "Transactions")) {
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
