import random
import math

numTransactions = 20000
year = 2022
months = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
users = ["Mike", "Darian"]
accounts = ["Savings", "Checking", "Visa"]
categories = ["Housing", "Transportation", "Food", "Utilities", "Insurance", "Medical", "Savings", "Personal", "Entertainment", "Miscellaneous", "Income", "Transfer", "Giftcard", "Fee", "Subscription", "Pet"]
for i in range(numTransactions):
  randomUser = random.choice(users)
  randomAccount = random.choice(accounts)
  randomCategory = random.choice(categories)
  randomAmount = round(random.uniform(-1000.0, 1000.0), 2)
  randomMonth = math.floor(random.uniform(0,11))
  randomDay = math.floor(random.uniform(1,daysPerMonth[randomMonth]+1))
  print(f'"{randomUser}","{year}-{months[randomMonth]}-{str(randomDay).zfill(2)}","{randomCategory}","{randomAccount}","{randomAmount}","Generated Transaction"')