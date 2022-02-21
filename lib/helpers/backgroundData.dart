// Objects to be able to store all the data for the different widgets to interact with
// ignore_for_file: constant_identifier_names, file_names
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:svg_icon/svg_icon.dart';

// Different categories that a transaction can be
enum Category {
  Housing,
  Utilities,
  Transportation,
  Insurance,
  Medical,
  Savings,
  Transfer,
  Fee,
  Income,
  Food,
  Groceries,
  Entertainment,
  Shopping,
  Subscription,
  Pet,
  Miscellaneous,
  Giftcard,
}

// Returns an icon depending on what category / size were given
Widget categoryToIcon(Category c, double size) {
  switch (c) {
    case Category.Housing:
      return Icon(Icons.home, size: size);
    case Category.Transportation:
      return Icon(Icons.commute, size: size);
    case Category.Groceries:
      return Icon(Icons.shopping_cart, size: size);
    case Category.Food:
      return Icon(Icons.local_pizza, size: size);
    case Category.Utilities:
      return Icon(Icons.outlet, size: size);
    case Category.Insurance:
      return Icon(Icons.assignment, size: size);
    case Category.Medical:
      return Icon(Icons.favorite, size: size);
    case Category.Savings:
      return Icon(Icons.savings, size: size);
    case Category.Shopping:
      return Icon(Icons.store, size: size);
    case Category.Entertainment:
      return SvgIcon(
        "icons/rocket_launch_white_24dp.svg",
        width: size,
        height: size,
      );
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
    case Category.Pet:
      return Icon(Icons.pets, size: size);
    default:
      return Icon(Icons.home, size: size);
  }
}

// Returns the category enum from a string
Category categoryFromString(String s) {
  switch (s) {
    case "Housing":
      return Category.Housing;
    case "Transportation":
      return Category.Transportation;
    case "Food":
      return Category.Food;
    case "Groceries":
      return Category.Groceries;
    case "Utilities":
      return Category.Utilities;
    case "Insurance":
      return Category.Insurance;
    case "Medical":
      return Category.Medical;
    case "Savings":
      return Category.Savings;
    case "Shopping":
      return Category.Shopping;
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
    case "Pet":
      return Category.Pet;
    default:
      return Category.Shopping;
  }
}

// Custom Account object
class Account {
  String user = "";
  String name = "Visa";
  double balance = 0.00;
  bool isGiftcard = false;
  Account();
  Account.withValues({
    required this.user,
    required this.name,
    required this.balance,
    required this.isGiftcard,
  });
  // Functions for working with json encoding / decoding
  Account.fromJson(Map<String, dynamic> json)
      : user = json['user'],
        name = json['name'],
        balance = json['balance'],
        isGiftcard = (json['isGiftcard'] == "true") ? true : false;
  Map<String, dynamic> toJson() {
    return {
      "user": user,
      "name": name,
      "balance": balance,
      "isGiftcard": isGiftcard
    };
  }
}

// Custom Transaction object
class Transaction {
  String guid = "";
  DateTime date = DateTime.now();
  Category category = Category.Shopping;
  String account = "";
  double amount = 0.0;
  String memo = "";
  String user = "";
  bool hasMemoImage = false;
  String? memoImagePath;
  InteractiveViewer? memoImageWidget;

  Transaction();
  Transaction.withValues(
      {required this.user,
      required this.date,
      required this.category,
      required this.account,
      required this.amount,
      required this.memo});

  // Functions for working with json encoding / decoding
  Transaction.fromJson(Map<String, dynamic> json)
      : guid = json['guid'],
        date = DateTime.parse(json['date']),
        category = categoryFromString(json['category']),
        account = json['account'],
        amount = json['amount'],
        memo = json['memo'],
        user = json['user'],
        hasMemoImage =
            (json.containsKey("hasMemoImage")) ? json['hasMemoImage'] : "";
  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "date":
          "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}",
      "category": category.toString().split('.').last,
      "account": account,
      "amount": amount,
      "memo": memo,
      "user": user,
      "hasMemoImage": hasMemoImage
    };
  }

  // Round the double to 2 decimals and return it as a string
  String strAmount() {
    return amount.toStringAsFixed(2);
  }

  @override
  String toString() {
    return "GUID: $guid | User: $user | Date: ${formatDate(date)} | Category: ${category.toString().split(".")[1]} | Account: $account | Amount: ${strAmount()} | Memo: $memo\n";
  }
}

// Generates a GUID for the given transaction
String generateGUID(Transaction t) {
  String content =
      "${t.user}${t.date.year}${t.date.month}${t.date.day}${t.category.toString()}${t.account}${t.amount}${t.memo}";
  return sha256.convert(utf8.encode(content)).toString();
}

// Turns an int into the 3 char month
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

// Custom object to hold all the financial data (transactions and accounts) that gets used for
//   filtering and analysis
class FinancialData {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  List<Account> accounts = [];
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  List<String> users = [];
  String currentUser = "None";
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
      if (t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1))) &&
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
  }

  // Returns a list of dropdown items for the current user accounts
  List<DropdownMenuItem<String>> getUserAccounts({bool all = true}) {
    List<DropdownMenuItem<String>> r = [];
    // Add the all option
    if (all) {
      r.add(const DropdownMenuItem<String>(
          value: "All",
          child: Text(
            "All",
            style: TextStyle(color: Colors.lightBlueAccent),
          )));
    }
    for (Account a in accounts) {
      if (a.user == currentUser) {
        r.add(DropdownMenuItem<String>(
            value: a.name,
            child: Text(
              a.name,
              style: const TextStyle(color: Colors.lightBlueAccent),
            )));
      }
    }
    return r;
  }

  FinancialData();

  FinancialData.fromJson(Map<String, dynamic> json, DateTimeRange dtr) {
    startDate = dtr.start;
    endDate = dtr.end;
    for (Map<String, dynamic> a in json['accounts']) {
      accounts.add(Account.fromJson(a));
      if (!users.contains(a['user'])) {
        users.add(a['user']);
      }
    }
    for (Map<String, dynamic> t in json['transactions']) {
      allTransactions.add(Transaction.fromJson(t));
    }
    currentUser = users[0];
    sortAccounts();
    sortTransactions();
  }

  Map<String, dynamic> toJson() {
    return {
      "accounts": accounts.map((e) => e.toJson()).toList(),
      "transactions": allTransactions.map((e) => e.toJson()).toList()
    };
  }

  @override
  String toString() {
    return "  startDate: ${formatDate(startDate)}\n  endDate: ${formatDate(endDate)}\n  accounts: ${accounts.toString()}\n  transactions: \n  ${filteredTransactions.toString()}";
  }
}
