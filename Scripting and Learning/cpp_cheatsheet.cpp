// =============================================================================
// C++ CHEAT SHEET — Beginner Reference
// =============================================================================

// Every C++ program needs these — include the standard library headers you use
#include <iostream>     // cin, cout
#include <string>       // std::string
#include <vector>       // std::vector
#include <map>          // std::map
#include <set>          // std::set
#include <algorithm>    // sort, find, min, max, etc.
#include <cmath>        // sqrt, pow, abs, floor, ceil
#include <fstream>      // file I/O
#include <sstream>      // string streams

// Avoid typing std:: everywhere by bringing the namespace into scope
// (fine for small programs and learning; avoid in large codebases)
using namespace std;


// =============================================================================
// MAIN FUNCTION — every C++ program starts here
// =============================================================================

// The OS calls main() when the program runs; return 0 means success
int main() {

    cout << "Hello, World!" << endl;

    return 0;
}

// NOTE: All examples below would live inside main() or their own functions.
//       They are written at file scope here for readability.


// =============================================================================
// VARIABLES & DATA TYPES
// =============================================================================

// C++ is statically typed — you must declare the type before using a variable
int     age      = 25;          // whole number  (4 bytes, -2B to 2B)
double  height   = 5.7;         // decimal, high precision (8 bytes)
float   weight   = 150.5f;      // decimal, lower precision (4 bytes) — note the f
char    grade    = 'A';         // single character — use single quotes
bool    isAdmin  = true;        // true or false
string  name     = "Alice";     // text — requires <string>

// long and short variants
long        bigNum  = 1234567890L;
long long   huge    = 9999999999999LL;
short       small   = 100;
unsigned int positive = 42;     // only positive numbers, doubles the max value

// auto — let the compiler infer the type (C++11 and later)
auto x = 42;            // int
auto pi = 3.14;         // double
auto word = "hello";    // const char*

// Constants — value cannot change after declaration
const double PI = 3.14159265;
const int MAX_SIZE = 100;


// =============================================================================
// INPUT & OUTPUT
// =============================================================================

// cout prints to the console — << is the insertion operator
cout << "Hello, World!" << endl;        // endl flushes the buffer and adds newline
cout << "Name: " << name << "\n";      // \n is faster than endl (no flush)
cout << "Age: " << age << endl;

// Print multiple values in one line
cout << "Name: " << name << ", Age: " << age << endl;

// cin reads input from the user — >> is the extraction operator
int userAge;
cout << "Enter your age: ";
cin >> userAge;

// Read a full line (including spaces) — cin >> stops at whitespace
string fullName;
cout << "Enter your full name: ";
cin.ignore();                   // discard the leftover newline from previous cin
getline(cin, fullName);

// Format output — setw sets column width, fixed/setprecision controls decimals
#include <iomanip>
cout << fixed << setprecision(2) << 3.14159;    // 3.14
cout << setw(10) << "right";                     // right-aligned in 10 chars


// =============================================================================
// OPERATORS
// =============================================================================

// Arithmetic
10 + 3      // 13
10 - 3      // 7
10 * 3      // 30
10 / 3      // 3     — integer division when both operands are int (truncates)
10.0 / 3    // 3.333 — at least one double gives floating-point result
10 % 3      // 1     — modulo (remainder), integers only

// Comparison — evaluate to true or false
5 == 5      // true
5 != 3      // true
5 >  3      // true
5 <  3      // false
5 >= 5      // true
5 <= 4      // false

// Logical
true && false   // false — AND
true || false   // true  — OR
!true           // false — NOT

// Bitwise
5 & 3       // 1    AND
5 | 3       // 7    OR
5 ^ 3       // 6    XOR
~5          // -6   NOT (bitwise complement)
1 << 3      // 8    left shift (multiply by 2^3)
8 >> 1      // 4    right shift (divide by 2^1)

// Augmented assignment
int n = 10;
n += 5;     // 15
n -= 3;     // 12
n *= 2;     // 24
n /= 4;     // 6
n++;        // 7   post-increment
++n;        // 8   pre-increment (increments before the expression is evaluated)
n--;        // 7   post-decrement

// Ternary operator — shorthand if/else
int absVal = (n < 0) ? -n : n;


// =============================================================================
// STRINGS
// =============================================================================

string greeting = "Hello, World!";

// String length
greeting.length()       // 13
greeting.size()         // 13 — same as length()

// Access a character by index
greeting[0]             // 'H'
greeting.at(0)          // 'H' — safer: throws exception if out of range

// Concatenation
string first = "Hello";
string second = " World";
string combined = first + second;   // "Hello World"
first += "!";                       // "Hello!"

// Substring — starting index, length
greeting.substr(7, 5)       // "World"

// Find — returns index of first match, or string::npos if not found
greeting.find("World")      // 7
greeting.find("xyz")        // string::npos

// Replace — starting index, how many chars to replace, replacement string
greeting.replace(7, 5, "C++");      // "Hello, C++!"

// Compare strings
string a = "apple", b = "banana";
a == b          // false
a < b           // true  — alphabetical comparison works with ==, <, >, etc.
a.compare(b)    // negative: a comes before b, 0: equal, positive: a comes after b

// Check if empty
greeting.empty()        // false
string empty = "";
empty.empty()           // true

// Convert to uppercase / lowercase — requires <algorithm> and <cctype>
#include <cctype>
for (char& c : greeting) c = toupper(c);   // modifies in place

// Convert number to string
string s = to_string(42);       // "42"
string d = to_string(3.14);     // "3.140000"

// Convert string to number
int   i  = stoi("42");          // 42
double d = stod("3.14");        // 3.14


// =============================================================================
// CONDITIONALS
// =============================================================================

int score = 85;

// if / else if / else
if (score >= 90) {
    cout << "A" << endl;
} else if (score >= 80) {
    cout << "B" << endl;
} else if (score >= 70) {
    cout << "C" << endl;
} else {
    cout << "F" << endl;
}

// Single-line — braces optional for one statement (but always use them)
if (score > 50) cout << "Pass" << endl;

// switch — compare one integer or char against fixed values
char letter = 'B';
switch (letter) {
    case 'A':
        cout << "Excellent" << endl;
        break;              // break is required — without it, falls through to next case
    case 'B':
    case 'C':               // two cases, one block — intentional fall-through
        cout << "Good" << endl;
        break;
    default:
        cout << "Other" << endl;
}

// Ternary — condition ? value_if_true : value_if_false
string result = (score >= 60) ? "Pass" : "Fail";


// =============================================================================
// LOOPS
// =============================================================================

// for — classic counter loop
for (int i = 0; i < 5; i++) {
    cout << i << " ";       // 0 1 2 3 4
}

// while — repeat while condition is true
int count = 0;
while (count < 5) {
    cout << count << " ";
    count++;
}

// do/while — always runs at least once
int num = 0;
do {
    cout << num << " ";
    num++;
} while (num < 5);

// Range-based for — iterate over a collection (C++11)
vector<string> fruits = {"apple", "banana", "cherry"};
for (const string& fruit : fruits) {
    cout << fruit << endl;
}

// Use auto to avoid spelling out the type
for (const auto& fruit : fruits) {
    cout << fruit << endl;
}

// break — exit the loop early
for (int i = 0; i < 10; i++) {
    if (i == 5) break;
    cout << i << " ";
}

// continue — skip the rest of this iteration
for (int i = 0; i < 10; i++) {
    if (i % 2 == 0) continue;  // skip even numbers
    cout << i << " ";           // 1 3 5 7 9
}


// =============================================================================
// FUNCTIONS
// =============================================================================

// Declare the return type before the function name
// Parameters are typed: (type name, type name, ...)
int add(int a, int b) {
    return a + b;
}

int result = add(3, 4);     // 7

// void — function that returns nothing
void printGreeting(string name) {
    cout << "Hello, " << name << "!" << endl;
}

// Default parameters — must be at the end of the parameter list
double power(double base, int exp = 2) {
    return pow(base, exp);
}
power(3.0);         // 9.0  (uses default exp=2)
power(3.0, 3);      // 27.0

// Function overloading — same name, different parameter types
int multiply(int a, int b)       { return a * b; }
double multiply(double a, double b) { return a * b; }

multiply(2, 3);         // calls int version
multiply(2.0, 3.0);     // calls double version

// Pass by reference — modifies the original variable
void doubleValue(int& n) {
    n *= 2;
}
int x2 = 5;
doubleValue(x2);        // x2 is now 10

// Pass by const reference — efficient for large objects, can't modify
void printName(const string& name) {
    cout << name << endl;
}

// Return multiple values using a pair or struct
pair<int, int> minMax(vector<int>& v) {
    return { *min_element(v.begin(), v.end()),
             *max_element(v.begin(), v.end()) };
}
auto [lo, hi] = minMax(someVec);    // structured binding (C++17)

// Function prototype — declare before main, define after
int subtract(int a, int b);         // prototype

int main() {
    cout << subtract(10, 3) << endl;
    return 0;
}

int subtract(int a, int b) {        // definition
    return a - b;
}


// =============================================================================
// ARRAYS
// =============================================================================

// Fixed-size array — size must be known at compile time
int scores[5] = {90, 85, 78, 92, 88};

// Access by index
scores[0]       // 90
scores[4]       // 88

// Iterate
for (int i = 0; i < 5; i++) {
    cout << scores[i] << endl;
}

// Get size of a C-style array
int size = sizeof(scores) / sizeof(scores[0]);  // 5

// 2D array — rows × columns
int grid[3][3] = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
};
grid[1][2]      // 6  (row 1, column 2)


// =============================================================================
// VECTORS — dynamic arrays (prefer these over raw arrays)
// =============================================================================

// Create a vector
vector<int> nums = {3, 1, 4, 1, 5, 9};
vector<string> words;               // empty vector

// Add and remove
nums.push_back(2);                  // add to end
nums.pop_back();                    // remove from end
nums.insert(nums.begin() + 1, 99); // insert 99 at index 1
nums.erase(nums.begin() + 1);      // remove element at index 1

// Access
nums[0]             // 3  — no bounds check
nums.at(0)          // 3  — throws exception if out of range
nums.front()        // first element
nums.back()         // last element

// Size and capacity
nums.size()         // number of elements
nums.empty()        // true if size == 0
nums.clear()        // remove all elements

// Iterate
for (const auto& n : nums) cout << n << " ";

// Sort
sort(nums.begin(), nums.end());                         // ascending
sort(nums.begin(), nums.end(), greater<int>());         // descending

// Find an element — returns iterator, compare to end() to check if found
auto it = find(nums.begin(), nums.end(), 5);
if (it != nums.end()) cout << "Found: " << *it << endl;

// Count occurrences
int c = count(nums.begin(), nums.end(), 1);     // how many 1s

// Vector of vectors — 2D dynamic array
vector<vector<int>> matrix = {
    {1, 2, 3},
    {4, 5, 6},
};
matrix[0][1]    // 2


// =============================================================================
// MAP — key/value pairs (sorted by key)
// =============================================================================

// Keys are unique and automatically sorted
map<string, int> ages;
ages["Alice"] = 25;
ages["Bob"]   = 30;
ages["Carol"] = 28;

// Access a value
ages["Alice"]           // 25
ages.at("Bob")          // 30 — throws if key missing (safer)

// Check if a key exists
ages.count("Alice")     // 1 (exists) or 0 (doesn't exist)
ages.find("Alice") != ages.end()    // true if found

// Remove a key
ages.erase("Bob");

// Iterate — pairs of (key, value)
for (const auto& [key, val] : ages) {
    cout << key << ": " << val << endl;
}

// unordered_map — same interface but faster (hash table, no sorting)
#include <unordered_map>
unordered_map<string, int> fastMap;
fastMap["x"] = 10;


// =============================================================================
// SET — unique, sorted values
// =============================================================================

set<int> nums2 = {3, 1, 4, 1, 5, 9, 2, 6};
// duplicates removed automatically: {1, 2, 3, 4, 5, 6, 9}

nums2.insert(7);
nums2.erase(3);
nums2.count(5)          // 1 (exists) or 0 (doesn't)
nums2.size()            // number of elements

for (const auto& n : nums2) cout << n << " ";

// unordered_set — faster, no sorting
#include <unordered_set>
unordered_set<string> seen;
seen.insert("apple");
seen.count("apple")     // 1


// =============================================================================
// POINTERS & REFERENCES
// =============================================================================

int val = 42;

// A pointer stores a memory address — declared with *
int* ptr = &val;        // & gets the address of val

*ptr        // 42       — dereference: get the value at the address
ptr         // memory address e.g. 0x7fff...

// Modify the original through the pointer
*ptr = 99;
cout << val << endl;    // 99

// Null pointer — points to nothing
int* null_ptr = nullptr;    // always initialize pointers

// Reference — an alias for an existing variable (must be initialized)
int& ref = val;
ref = 100;              // modifies val directly
cout << val << endl;    // 100

// Pointer arithmetic — move to next element in an array
int arr[] = {10, 20, 30};
int* p = arr;           // points to arr[0]
*(p + 1)                // 20  — arr[1]
*(p + 2)                // 30  — arr[2]

// Dynamic memory allocation — allocates on the heap
int* heap = new int(5);     // allocate a single int with value 5
delete heap;                // always free heap memory when done

int* arr2 = new int[10];    // allocate array of 10 ints
delete[] arr2;              // use delete[] for arrays


// =============================================================================
// STRUCTS
// =============================================================================

// A struct groups related data under one name
struct Point {
    double x;
    double y;
};

// Create and use a struct
Point p1 = {3.0, 4.0};
p1.x        // 3.0
p1.y        // 4.0

// Struct with a constructor and method
struct Rectangle {
    double width;
    double height;

    // Constructor
    Rectangle(double w, double h) : width(w), height(h) {}

    // Method
    double area() const {
        return width * height;
    }
};

Rectangle rect(5.0, 3.0);
rect.area()     // 15.0


// =============================================================================
// CLASSES & OBJECTS
// =============================================================================

// A class is like a struct but with access control
// public: accessible from outside the class
// private: only accessible from inside the class (default in class)
class Dog {
private:
    string name;    // private — can't access directly from outside
    string breed;
    int    age;

public:
    // Constructor — same name as the class, no return type
    // Initializer list (:) is the preferred way to set member variables
    Dog(string n, string b, int a) : name(n), breed(b), age(a) {}

    // Getter methods — const means they don't modify the object
    string getName()  const { return name; }
    string getBreed() const { return breed; }
    int    getAge()   const { return age; }

    // Setter method
    void setAge(int a) {
        if (a >= 0) age = a;    // validate before setting
    }

    // Regular method
    string bark() const {
        return name + " says: Woof!";
    }

    // Destructor — called automatically when the object is destroyed
    ~Dog() {
        cout << name << " destroyed" << endl;
    }
};

// Create objects on the stack (automatic memory management)
Dog myDog("Rex", "Labrador", 3);
myDog.getName()     // "Rex"
myDog.bark()        // "Rex says: Woof!"
myDog.setAge(4);

// Create object on the heap (manual memory management)
Dog* heapDog = new Dog("Buddy", "Poodle", 2);
heapDog->getName()  // -> is used to access members through a pointer
delete heapDog;     // must free manually


// =============================================================================
// INHERITANCE
// =============================================================================

// Base class
class Animal {
protected:          // protected: accessible in this class AND derived classes
    string name;

public:
    Animal(string n) : name(n) {}

    // virtual — allows derived classes to override this method
    virtual string speak() const {
        return name + " makes a sound";
    }

    // Pure virtual — makes this class abstract (cannot instantiate Animal directly)
    // virtual string speak() const = 0;

    virtual ~Animal() {}    // virtual destructor — always use with inheritance
};

// Derived class
class Cat : public Animal {
private:
    string color;

public:
    Cat(string n, string c) : Animal(n), color(c) {}   // call parent constructor

    // Override the base class method
    string speak() const override {     // override keyword catches typos
        return name + " says: Meow!";
    }

    string getColor() const { return color; }
};

Animal* a = new Cat("Luna", "black");
a->speak()      // "Luna says: Meow!" — polymorphism: calls Cat's version
delete a;


// =============================================================================
// TEMPLATES — write one function/class that works for any type
// =============================================================================

// Template function
template <typename T>
T maximum(T a, T b) {
    return (a > b) ? a : b;
}

maximum(3, 7)           // 7   (int)
maximum(3.5, 2.1)       // 3.5 (double)
maximum('a', 'z')       // 'z' (char)

// Template class
template <typename T>
class Box {
private:
    T value;
public:
    Box(T v) : value(v) {}
    T get() const { return value; }
};

Box<int>    intBox(42);
Box<string> strBox("hello");
intBox.get()    // 42
strBox.get()    // "hello"


// =============================================================================
// ERROR HANDLING — EXCEPTIONS
// =============================================================================

// throw, try, catch — same pattern as other languages
try {
    int a = 10, b = 0;
    if (b == 0) throw runtime_error("Division by zero");
    cout << a / b << endl;
}
catch (const runtime_error& e) {
    cout << "Error: " << e.what() << endl;
}
catch (...) {
    cout << "Unknown error" << endl;    // catch-all
}

// Common standard exception types
// runtime_error  — general runtime errors
// out_of_range   — index out of bounds
// invalid_argument — bad argument value
// overflow_error — arithmetic overflow
// bad_alloc      — new failed (out of memory)

// Throw and re-throw
void riskyFunction() {
    throw invalid_argument("Bad input");
}

try {
    riskyFunction();
} catch (const invalid_argument& e) {
    cout << e.what() << endl;
    throw;      // re-throw the same exception up the call stack
}


// =============================================================================
// FILE I/O
// =============================================================================

// Write to a file
ofstream outFile("output.txt");
if (outFile.is_open()) {
    outFile << "Hello, file!" << endl;
    outFile << "Second line" << endl;
    outFile.close();
}

// Append to a file — open with ios::app flag
ofstream appendFile("output.txt", ios::app);
appendFile << "Appended line" << endl;
appendFile.close();

// Read from a file line by line
ifstream inFile("output.txt");
string line;
while (getline(inFile, line)) {
    cout << line << endl;
}
inFile.close();

// Read word by word
ifstream wordFile("output.txt");
string word;
while (wordFile >> word) {
    cout << word << " ";
}

// Check if file opened successfully
ifstream f("missing.txt");
if (!f.is_open()) {
    cout << "File not found" << endl;
}


// =============================================================================
// LAMBDA FUNCTIONS (C++11)
// =============================================================================

// [capture](parameters) -> return_type { body }
// The return type can usually be omitted — the compiler infers it

// A simple lambda assigned to a variable
auto square = [](int x) { return x * x; };
square(5)   // 25

// Lambda used directly with an algorithm
vector<int> v = {3, 1, 4, 1, 5, 9};
sort(v.begin(), v.end(), [](int a, int b) { return a > b; });   // descending sort

// Capture a variable from the surrounding scope by value [=]
int factor = 3;
auto triple = [factor](int x) { return x * factor; };
triple(5)   // 15

// Capture by reference [&] — can read AND modify the outer variable
int total = 0;
for_each(v.begin(), v.end(), [&total](int n) { total += n; });
cout << total << endl;

// for_each with a lambda — apply a function to every element
for_each(v.begin(), v.end(), [](int n) { cout << n << " "; });


// =============================================================================
// USEFUL STANDARD LIBRARY ALGORITHMS  (requires <algorithm>)
// =============================================================================

vector<int> nums3 = {3, 1, 4, 1, 5, 9, 2, 6};

// Sort
sort(nums3.begin(), nums3.end());                       // ascending in-place
sort(nums3.begin(), nums3.end(), greater<int>());       // descending

// Find
auto it2 = find(nums3.begin(), nums3.end(), 5);          // iterator to first 5
if (it2 != nums3.end()) cout << *it2 << endl;

// Min / Max
*min_element(nums3.begin(), nums3.end())    // smallest value
*max_element(nums3.begin(), nums3.end())    // largest value
min(3, 7)                                   // 3  — simple two-value version
max(3, 7)                                   // 7

// Count
count(nums3.begin(), nums3.end(), 1)        // how many 1s

// Accumulate / sum  (requires <numeric>)
#include <numeric>
accumulate(nums3.begin(), nums3.end(), 0)   // sum of all elements

// Reverse in place
reverse(nums3.begin(), nums3.end());

// Remove duplicates — must sort first, then erase the "removed" tail
sort(nums3.begin(), nums3.end());
nums3.erase(unique(nums3.begin(), nums3.end()), nums3.end());

// Fill a range with a value
vector<int> zeros(5);
fill(zeros.begin(), zeros.end(), 0);        // {0, 0, 0, 0, 0}

// Check if any / all elements satisfy a condition
any_of(nums3.begin(), nums3.end(), [](int n) { return n > 5; })   // true
all_of(nums3.begin(), nums3.end(), [](int n) { return n > 0; })   // true

// Transform — apply a function to each element, store result
vector<int> doubled(nums3.size());
transform(nums3.begin(), nums3.end(), doubled.begin(), [](int n) { return n * 2; });


// =============================================================================
// MEMORY — SMART POINTERS (C++11)  (requires <memory>)
// Prefer these over raw new/delete — they manage memory automatically
// =============================================================================

#include <memory>

// unique_ptr — one owner, automatically deleted when out of scope
unique_ptr<Dog> dog1 = make_unique<Dog>("Rex", "Lab", 3);
dog1->getName()     // "Rex"
// dog1 is automatically deleted when it goes out of scope — no delete needed

// Move ownership — unique_ptr cannot be copied, only moved
unique_ptr<Dog> dog2 = move(dog1);
// dog1 is now null; dog2 owns the Dog

// shared_ptr — multiple owners, deleted when last owner goes out of scope
shared_ptr<Dog> sharedDog = make_shared<Dog>("Buddy", "Poodle", 2);
shared_ptr<Dog> anotherRef = sharedDog;    // both point to the same Dog
sharedDog.use_count()   // 2 — two owners

// weak_ptr — observes a shared_ptr without owning it (prevents circular refs)
weak_ptr<Dog> weakDog = sharedDog;
if (auto locked = weakDog.lock()) {     // lock() gets a temporary shared_ptr
    locked->getName();
}
