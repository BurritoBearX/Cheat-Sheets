# =============================================================================
# PYTHON CHEAT SHEET — Beginner Reference
# =============================================================================


# =============================================================================
# VARIABLES & DATA TYPES
# =============================================================================

# Assign values — Python infers the type automatically
name = "Alice"          # str  (text)
age = 25                # int  (whole number)
height = 5.7            # float (decimal)
is_admin = True         # bool (True or False)
nothing = None          # NoneType (absence of value)

# Check a variable's type
type(name)              # <class 'str'>

# Convert between types (casting)
str(42)                 # "42"
int("10")               # 10
float("3.14")           # 3.14
bool(0)                 # False  — 0, "", [], None are all falsy


# =============================================================================
# STRINGS
# =============================================================================

# Define strings with single or double quotes
greeting = "Hello, World!"

# Access individual characters by index (zero-based)
greeting[0]             # 'H'
greeting[-1]            # '!'  — negative index counts from the end

# Slice a range of characters  [start:stop]  (stop is exclusive)
greeting[0:5]           # 'Hello'
greeting[7:]            # 'World!'

# Common string methods
"hello".upper()         # 'HELLO'
"HELLO".lower()         # 'hello'
"  hi  ".strip()        # 'hi'   — removes surrounding whitespace
"a,b,c".split(",")      # ['a', 'b', 'c']
"hi".replace("h", "H")  # 'Hi'
len("hello")            # 5

# f-strings — embed variables directly in a string
name = "Alice"
age = 25
print(f"My name is {name} and I am {age} years old.")
# My name is Alice and I am 25 years old.


# =============================================================================
# NUMBERS & MATH
# =============================================================================

# Basic arithmetic operators
10 + 3      # 13   addition
10 - 3      # 7    subtraction
10 * 3      # 30   multiplication
10 / 3      # 3.333...  true division (always returns float)
10 // 3     # 3    floor division (drops the decimal)
10 % 3      # 1    modulo (remainder)
2 ** 8      # 256  exponentiation

# Augmented assignment — shorthand for updating a variable
x = 10
x += 5      # x is now 15
x *= 2      # x is now 30


# =============================================================================
# LISTS
# =============================================================================

# An ordered, mutable collection of items
fruits = ["apple", "banana", "cherry"]

# Access by index
fruits[0]           # 'apple'
fruits[-1]          # 'cherry'

# Slicing
fruits[0:2]         # ['apple', 'banana']

# Modify
fruits[1] = "mango"                 # replace
fruits.append("grape")              # add to end
fruits.insert(0, "kiwi")           # insert at index
fruits.remove("apple")             # remove by value
popped = fruits.pop()              # remove and return last item
fruits.sort()                      # sort in place
fruits.reverse()                   # reverse in place
len(fruits)                        # number of items

# Check membership
"banana" in fruits      # True or False

# Loop through a list
for fruit in fruits:
    print(fruit)


# =============================================================================
# TUPLES
# =============================================================================

# Like a list but immutable — cannot be changed after creation
coordinates = (10, 20)
rgb = (255, 128, 0)

# Access by index (same as list)
coordinates[0]      # 10

# Unpack values into variables
x, y = coordinates
# x = 10, y = 20


# =============================================================================
# DICTIONARIES
# =============================================================================

# Key-value pairs — unordered, mutable, keys must be unique
person = {
    "name": "Alice",
    "age": 25,
    "city": "NYC"
}

# Access a value by key
person["name"]              # 'Alice'
person.get("age")           # 25  — .get() returns None if key missing

# Add or update a key
person["email"] = "alice@example.com"
person["age"] = 26

# Remove a key
del person["city"]
removed = person.pop("email")   # removes and returns the value

# Loop through keys and values
for key, value in person.items():
    print(f"{key}: {value}")

# Useful methods
person.keys()       # dict_keys(['name', 'age'])
person.values()     # dict_values(['Alice', 26])
"name" in person    # True — check if key exists


# =============================================================================
# SETS
# =============================================================================

# Unordered collection of UNIQUE items
colors = {"red", "green", "blue", "red"}   # duplicate dropped
# colors = {'red', 'green', 'blue'}

colors.add("yellow")
colors.remove("green")

# Set operations
a = {1, 2, 3}
b = {2, 3, 4}
a | b       # {1, 2, 3, 4}  union
a & b       # {2, 3}        intersection
a - b       # {1}           difference (in a, not in b)


# =============================================================================
# CONDITIONALS
# =============================================================================

# Execute code based on whether a condition is True or False
score = 85

if score >= 90:
    print("A")
elif score >= 80:
    print("B")
elif score >= 70:
    print("C")
else:
    print("F")

# Comparison operators
# ==   equal to
# !=   not equal to
# >    greater than
# <    less than
# >=   greater than or equal
# <=   less than or equal

# Logical operators combine conditions
age = 20
has_id = True

if age >= 18 and has_id:
    print("Allowed")

if age < 13 or age > 65:
    print("Discount applies")

if not has_id:
    print("No ID, denied")

# Inline conditional (ternary)
label = "adult" if age >= 18 else "minor"


# =============================================================================
# LOOPS
# =============================================================================

# for — iterate over a sequence
for i in range(5):          # 0, 1, 2, 3, 4
    print(i)

for i in range(1, 6):       # 1, 2, 3, 4, 5
    print(i)

for i in range(0, 10, 2):   # 0, 2, 4, 6, 8  (step of 2)
    print(i)

# while — repeat as long as condition is True
count = 0
while count < 5:
    print(count)
    count += 1

# break — exit the loop early
for n in range(10):
    if n == 5:
        break           # stops at 5

# continue — skip the rest of this iteration
for n in range(10):
    if n % 2 == 0:
        continue        # skip even numbers
    print(n)            # prints 1, 3, 5, 7, 9

# enumerate — loop with index AND value
fruits = ["apple", "banana", "cherry"]
for i, fruit in enumerate(fruits):
    print(f"{i}: {fruit}")

# zip — loop over two lists together
names = ["Alice", "Bob"]
scores = [95, 87]
for name, score in zip(names, scores):
    print(f"{name}: {score}")

# List comprehension — compact way to build a list
squares = [x ** 2 for x in range(1, 6)]
# [1, 4, 9, 16, 25]

evens = [x for x in range(20) if x % 2 == 0]
# [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]


# =============================================================================
# FUNCTIONS
# =============================================================================

# Define a reusable block of code with def
def greet(name):
    print(f"Hello, {name}!")

greet("Alice")      # Hello, Alice!

# Return a value from a function
def add(a, b):
    return a + b

result = add(3, 4)  # 7

# Default parameter — used when argument is not provided
def greet(name, greeting="Hello"):
    return f"{greeting}, {name}!"

greet("Alice")              # 'Hello, Alice!'
greet("Alice", "Hey")       # 'Hey, Alice!'

# *args — accept any number of positional arguments
def total(*numbers):
    return sum(numbers)

total(1, 2, 3, 4)           # 10

# **kwargs — accept any number of keyword arguments
def display(**info):
    for key, value in info.items():
        print(f"{key}: {value}")

display(name="Alice", age=25)

# Lambda — a small, anonymous one-line function
square = lambda x: x ** 2
square(5)           # 25

double = lambda x: x * 2
sorted([3, 1, 4], key=lambda x: -x)    # [4, 3, 1]


# =============================================================================
# ERROR HANDLING
# =============================================================================

# try/except catches errors so the program doesn't crash
try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero")

# Handle multiple exception types
try:
    value = int("abc")
except ValueError:
    print("Not a valid number")
except TypeError:
    print("Wrong type provided")

# else runs only if no exception occurred
# finally always runs (cleanup code)
try:
    f = open("file.txt")
except FileNotFoundError:
    print("File not found")
else:
    print("File opened successfully")
finally:
    print("Done attempting")

# Raise your own exception
def divide(a, b):
    if b == 0:
        raise ValueError("Denominator cannot be zero")
    return a / b


# =============================================================================
# CLASSES & OBJECTS
# =============================================================================

# A class is a blueprint for creating objects
class Dog:

    # __init__ runs automatically when an object is created
    def __init__(self, name, breed):
        self.name = name        # instance attribute
        self.breed = breed

    # A method is a function that belongs to the class
    def bark(self):
        return f"{self.name} says: Woof!"

    # __str__ controls what prints when you print the object
    def __str__(self):
        return f"Dog({self.name}, {self.breed})"


# Create an instance (object) of the class
my_dog = Dog("Rex", "Labrador")

# Access attributes
my_dog.name         # 'Rex'
my_dog.breed        # 'Labrador'

# Call a method
my_dog.bark()       # 'Rex says: Woof!'
print(my_dog)       # Dog(Rex, Labrador)


# =============================================================================
# INHERITANCE
# =============================================================================

# A child class inherits attributes and methods from a parent class
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return "..."

# Dog inherits from Animal
class Dog(Animal):
    def speak(self):                        # override the parent method
        return f"{self.name} says Woof!"

class Cat(Animal):
    def speak(self):
        return f"{self.name} says Meow!"

# super() calls the parent class's __init__
class ServiceDog(Dog):
    def __init__(self, name, role):
        super().__init__(name)              # runs Dog/Animal __init__
        self.role = role

    def describe(self):
        return f"{self.name} is a {self.role} dog"


dog = Dog("Rex")
cat = Cat("Luna")
dog.speak()         # 'Rex says Woof!'
cat.speak()         # 'Luna says Meow!'


# =============================================================================
# MODULES & IMPORTS
# =============================================================================

# Import a built-in module
import math
math.sqrt(16)       # 4.0
math.pi             # 3.141592...
math.floor(3.9)     # 3

import random
random.randint(1, 10)           # random int between 1 and 10
random.choice(["a", "b", "c"]) # random element

import os
os.getcwd()         # current working directory
os.listdir(".")     # list files in current directory

# Import specific items from a module
from datetime import datetime
now = datetime.now()
print(now.strftime("%Y-%m-%d"))     # 2024-01-15

# Import with an alias
import math as m
m.sqrt(25)          # 5.0


# =============================================================================
# FILE I/O
# =============================================================================

# Write to a file — 'w' creates or overwrites
with open("output.txt", "w") as f:
    f.write("Hello, file!\n")
    f.write("Second line\n")

# Read entire file contents
with open("output.txt", "r") as f:
    content = f.read()

# Read line by line
with open("output.txt", "r") as f:
    for line in f:
        print(line.strip())

# Append to an existing file without overwriting
with open("output.txt", "a") as f:
    f.write("Appended line\n")

# 'with' automatically closes the file — always prefer it


# =============================================================================
# USEFUL BUILT-IN FUNCTIONS
# =============================================================================

# Work with collections
len([1, 2, 3])              # 3
sum([1, 2, 3])              # 6
min([3, 1, 4])              # 1
max([3, 1, 4])              # 4
sorted([3, 1, 4])           # [1, 3, 4]
sorted([3, 1, 4], reverse=True)     # [4, 3, 1]
list(reversed([1, 2, 3]))   # [3, 2, 1]

# Map and filter — apply a function to each item, or filter items
numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x * 2, numbers))      # [2, 4, 6, 8, 10]
odds = list(filter(lambda x: x % 2 != 0, numbers)) # [1, 3, 5]

# any / all — check conditions across a collection
any([False, True, False])   # True  — at least one is True
all([True, True, True])     # True  — all are True
all([True, False, True])    # False

# Input from user
name = input("Enter your name: ")  # waits for user to type
