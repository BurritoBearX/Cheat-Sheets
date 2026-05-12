// =============================================================================
// JAVASCRIPT CHEAT SHEET — Beginner Reference
// =============================================================================


// =============================================================================
// VARIABLES
// =============================================================================

// const — cannot be reassigned (prefer this by default)
const name = "Alice";

// let — can be reassigned, block-scoped
let age = 25;
age = 26;       // ok

// var — old style, function-scoped, avoid in modern code
var old = "don't use this";

// Multiple assignment
const x = 1, y = 2, z = 3;


// =============================================================================
// DATA TYPES
// =============================================================================

const str    = "Hello";            // string
const num    = 42;                 // number (JS has no int/float distinction)
const dec    = 3.14;               // also a number
const bool   = true;               // boolean
const empty  = null;               // intentional absence of value
const undef  = undefined;          // variable declared but not assigned
const sym    = Symbol("id");       // unique identifier (advanced)

// Check the type of a value
typeof "hello"      // "string"
typeof 42           // "number"
typeof true         // "boolean"
typeof null         // "object" — this is a known JS quirk
typeof undefined    // "undefined"


// =============================================================================
// STRINGS
// =============================================================================

const greeting = "Hello, World!";

// Access characters by index
greeting[0]             // 'H'
greeting.at(-1)         // '!' — negative index from the end

// String length
greeting.length         // 13

// Common string methods
"hello".toUpperCase()           // 'HELLO'
"HELLO".toLowerCase()           // 'hello'
"  hi  ".trim()                 // 'hi'
"a,b,c".split(",")              // ['a', 'b', 'c']
"hello world".includes("world") // true
"hello".startsWith("he")        // true
"hello".endsWith("lo")          // true
"hello".indexOf("l")            // 2 — index of first match, -1 if not found
"hello".replace("l", "r")       // 'herlo' — replaces first match
"hello".replaceAll("l", "r")    // 'herro' — replaces all matches
"ha".repeat(3)                  // 'hahaha'
"hello".slice(1, 4)             // 'ell' — [start, end) exclusive

// Template literals — backticks allow embedded expressions and multi-line
const user = "Alice";
const msg = `Hello, ${user}! You are ${20 + 5} years old.`;

// Multi-line string
const multiLine = `
    Line one
    Line two
    Line three
`;


// =============================================================================
// NUMBERS & MATH
// =============================================================================

10 + 3          // 13
10 - 3          // 7
10 * 3          // 30
10 / 3          // 3.3333...
10 % 3          // 1    remainder
2 ** 8          // 256  exponentiation

// Augmented assignment
let n = 10;
n += 5;         // 15
n++;            // 16  increment by 1
n--;            // 15  decrement by 1

// Math object
Math.round(4.6)     // 5
Math.floor(4.9)     // 4    round down
Math.ceil(4.1)      // 5    round up
Math.abs(-7)        // 7    absolute value
Math.max(1, 5, 3)   // 5
Math.min(1, 5, 3)   // 1
Math.sqrt(16)       // 4
Math.random()       // random float between 0 and 1

// Random integer between min and max (inclusive)
const rand = Math.floor(Math.random() * (max - min + 1)) + min;

// Convert string to number
Number("42")        // 42
parseInt("42px")    // 42     parses up to the first non-numeric character
parseFloat("3.14")  // 3.14

// Check for invalid number result
isNaN(NaN)          // true
isNaN("hello")      // true
Number.isFinite(1/0)// false


// =============================================================================
// ARRAYS
// =============================================================================

const fruits = ["apple", "banana", "cherry"];

// Access by index
fruits[0]           // 'apple'
fruits.at(-1)       // 'cherry'

// Length
fruits.length       // 3

// Add and remove items
fruits.push("grape")            // add to end       → returns new length
fruits.pop()                    // remove from end   → returns removed item
fruits.unshift("kiwi")          // add to start      → returns new length
fruits.shift()                  // remove from start → returns removed item

// Find items
fruits.includes("banana")       // true
fruits.indexOf("banana")        // 1   (-1 if not found)
fruits.find(x => x.length > 5)  // 'banana' — first match
fruits.findIndex(x => x === "cherry") // 2

// Transform — these return NEW arrays, do not mutate the original
fruits.map(f => f.toUpperCase())        // ['APPLE', 'BANANA', 'CHERRY']
fruits.filter(f => f.length > 5)        // ['banana', 'cherry']
fruits.slice(1, 3)                      // ['banana', 'cherry']  [start, end)

// Reduce — collapse an array to a single value
[1, 2, 3, 4].reduce((acc, cur) => acc + cur, 0)    // 10

// Sort — mutates the original array
fruits.sort()                           // alphabetical
[3, 1, 4].sort((a, b) => a - b)        // [1, 3, 4] ascending
[3, 1, 4].sort((a, b) => b - a)        // [4, 3, 1] descending

// Flatten nested arrays
[[1, 2], [3, 4]].flat()                // [1, 2, 3, 4]

// Check if every / some items pass a test
[2, 4, 6].every(n => n % 2 === 0)     // true — all even
[1, 2, 3].some(n => n > 2)            // true — at least one > 2

// Combine arrays
const combined = [...fruits, "mango", "peach"];   // spread operator

// Destructure — unpack array values into variables
const [first, second, ...rest] = fruits;
// first = 'apple', second = 'banana', rest = ['cherry']

// Loop through an array
fruits.forEach(fruit => console.log(fruit));


// =============================================================================
// OBJECTS
// =============================================================================

const person = {
    name: "Alice",
    age: 25,
    city: "NYC",
    greet() {                           // shorthand method
        return `Hi, I'm ${this.name}`;
    }
};

// Access properties
person.name             // 'Alice'  — dot notation
person["age"]           // 25       — bracket notation (useful for dynamic keys)

// Add or update a property
person.email = "alice@example.com";
person.age = 26;

// Delete a property
delete person.city;

// Check if a key exists
"name" in person        // true

// Object methods
Object.keys(person)     // ['name', 'age', 'email']
Object.values(person)   // ['Alice', 26, 'alice@example.com']
Object.entries(person)  // [['name','Alice'], ['age',26], ...]

// Loop through an object
for (const [key, value] of Object.entries(person)) {
    console.log(`${key}: ${value}`);
}

// Destructure — unpack object properties into variables
const { name, age } = person;
// name = 'Alice', age = 26

// Rename during destructure
const { name: fullName } = person;
// fullName = 'Alice'

// Default value during destructure
const { role = "user" } = person;
// role = 'user' (since person.role is undefined)

// Spread — shallow copy or merge objects
const copy = { ...person };
const merged = { ...person, role: "admin", age: 30 };


// =============================================================================
// CONDITIONALS
// =============================================================================

const score = 85;

if (score >= 90) {
    console.log("A");
} else if (score >= 80) {
    console.log("B");
} else {
    console.log("C or below");
}

// Ternary — one-line if/else
const label = score >= 60 ? "Pass" : "Fail";

// Nullish coalescing — use right side only when left is null or undefined
const username = null;
const display = username ?? "Guest";    // 'Guest'

// Optional chaining — safely access nested properties without errors
const street = person?.address?.street;    // undefined instead of throwing

// Switch — compare one value against many cases
const day = "Monday";
switch (day) {
    case "Monday":
    case "Tuesday":
        console.log("Early week");
        break;
    case "Friday":
        console.log("End of week");
        break;
    default:
        console.log("Midweek");
}


// =============================================================================
// LOOPS
// =============================================================================

// for — classic loop with counter
for (let i = 0; i < 5; i++) {
    console.log(i);     // 0, 1, 2, 3, 4
}

// while — repeat while condition is true
let count = 0;
while (count < 5) {
    console.log(count);
    count++;
}

// for...of — iterate over arrays (or any iterable)
const colors = ["red", "green", "blue"];
for (const color of colors) {
    console.log(color);
}

// for...in — iterate over object keys
for (const key in person) {
    console.log(key, person[key]);
}

// break and continue work the same as Python
for (let i = 0; i < 10; i++) {
    if (i === 5) break;         // stop the loop
    if (i % 2 === 0) continue;  // skip even numbers
    console.log(i);
}


// =============================================================================
// FUNCTIONS
// =============================================================================

// Function declaration — hoisted (can be called before it's defined)
function add(a, b) {
    return a + b;
}
add(3, 4);      // 7

// Function expression — not hoisted
const multiply = function(a, b) {
    return a * b;
};

// Arrow function — concise syntax, no own 'this' binding
const square = (x) => x ** 2;          // implicit return for single expression
const greet = (name) => {
    const msg = `Hello, ${name}`;
    return msg;                         // explicit return needed in a block body
};
const double = x => x * 2;             // parentheses optional for one parameter

// Default parameters
function greetUser(name = "Guest") {
    return `Hello, ${name}!`;
}
greetUser();            // 'Hello, Guest!'
greetUser("Alice");     // 'Hello, Alice!'

// Rest parameters — collect extra arguments into an array
function sum(...numbers) {
    return numbers.reduce((a, b) => a + b, 0);
}
sum(1, 2, 3, 4);        // 10

// Immediately Invoked Function Expression (IIFE) — runs instantly
(function() {
    console.log("Runs immediately");
})();


// =============================================================================
// SCOPE & CLOSURES
// =============================================================================

// Variables declared with let/const inside a block are scoped to that block
{
    let blockVar = "only here";
}
// blockVar is not accessible out here

// A closure — an inner function that "remembers" the outer function's variables
function makeCounter() {
    let count = 0;                  // this variable is captured by the closure
    return function() {
        count++;
        return count;
    };
}
const counter = makeCounter();
counter();      // 1
counter();      // 2
counter();      // 3


// =============================================================================
// DOM MANIPULATION
// =============================================================================

// Select a single element — returns the first match
const heading = document.querySelector("h1");
const card    = document.querySelector(".card");
const hero    = document.querySelector("#hero");

// Select all matching elements — returns a NodeList
const allCards = document.querySelectorAll(".card");

// Read and write content
heading.textContent = "New Heading";            // plain text (safe)
heading.innerHTML   = "<em>New</em> Heading";   // parses HTML (be careful)

// Read and write attributes
const link = document.querySelector("a");
link.getAttribute("href");          // '/page'
link.setAttribute("href", "/new-page");
link.removeAttribute("target");

// Read and write styles
heading.style.color     = "red";
heading.style.fontSize  = "2rem";

// CSS classes
const box = document.querySelector(".box");
box.classList.add("active");
box.classList.remove("hidden");
box.classList.toggle("open");           // adds if absent, removes if present
box.classList.contains("active");       // true or false

// Create and insert elements
const newPara = document.createElement("p");
newPara.textContent = "I was added by JavaScript";
document.body.appendChild(newPara);                 // add at end of body

const list = document.querySelector("ul");
list.insertAdjacentHTML("beforeend", "<li>New item</li>");  // faster for HTML

// Remove an element
newPara.remove();


// =============================================================================
// EVENTS
// =============================================================================

const btn = document.querySelector("button");

// Listen for a click event — runs the function when the button is clicked
btn.addEventListener("click", function(event) {
    console.log("Button clicked!");
    console.log(event.target);     // the element that was clicked
});

// Arrow function syntax for event listeners
btn.addEventListener("click", (e) => {
    console.log(e.target.textContent);
});

// Prevent the default browser action (e.g., stop a form from submitting)
const form = document.querySelector("form");
form.addEventListener("submit", (e) => {
    e.preventDefault();
    console.log("Form intercepted");
});

// Common event types
// "click"       — mouse click
// "dblclick"    — double click
// "mouseover"   — mouse enters element
// "mouseout"    — mouse leaves element
// "keydown"     — key pressed down
// "keyup"       — key released
// "input"       — input field value changes
// "change"      — select/checkbox value changes
// "focus"       — element receives focus
// "blur"        — element loses focus
// "submit"      — form submitted
// "load"        — page or resource finished loading
// "DOMContentLoaded" — HTML parsed (before images/stylesheets load)

// Run code after the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
    console.log("DOM ready");
});


// =============================================================================
// PROMISES & ASYNC / AWAIT
// =============================================================================

// A Promise represents a value that will arrive in the future
const myPromise = new Promise((resolve, reject) => {
    const success = true;
    if (success) {
        resolve("It worked!");
    } else {
        reject("It failed.");
    }
});

// Handle the promise with .then() / .catch() / .finally()
myPromise
    .then(result => console.log(result))     // runs on resolve
    .catch(error => console.log(error))      // runs on reject
    .finally(() => console.log("Done"));     // always runs

// async/await — cleaner syntax for working with Promises
async function fetchUser() {
    try {
        const response = await fetch("https://api.example.com/user");
        const data     = await response.json();
        console.log(data);
    } catch (error) {
        console.log("Error:", error);
    }
}

fetchUser();

// Run multiple async operations in parallel
async function fetchAll() {
    const [users, posts] = await Promise.all([
        fetch("/api/users").then(r => r.json()),
        fetch("/api/posts").then(r => r.json()),
    ]);
    console.log(users, posts);
}


// =============================================================================
// FETCH API — make HTTP requests
// =============================================================================

// GET request — fetch data from a server
async function getData() {
    const response = await fetch("https://api.example.com/data");
    const data = await response.json();
    return data;
}

// POST request — send data to a server
async function postData(payload) {
    const response = await fetch("https://api.example.com/data", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),      // convert object to JSON string
    });
    const result = await response.json();
    return result;
}

// Check if the request succeeded
async function safeGet(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`HTTP error: ${response.status}`);
    }
    return response.json();
}


// =============================================================================
// LOCAL STORAGE — persist data in the browser
// =============================================================================

// Save a value (only strings allowed — use JSON for objects)
localStorage.setItem("username", "Alice");
localStorage.setItem("settings", JSON.stringify({ theme: "dark", lang: "en" }));

// Read a value
const user2 = localStorage.getItem("username");         // 'Alice'
const settings = JSON.parse(localStorage.getItem("settings")); // { theme: 'dark', ... }

// Remove a single key
localStorage.removeItem("username");

// Clear everything
localStorage.clear();

// sessionStorage works the same way but clears when the tab is closed
sessionStorage.setItem("token", "abc123");


// =============================================================================
// ERROR HANDLING
// =============================================================================

// try/catch/finally — same idea as Python
try {
    const result = JSON.parse("not valid json");
} catch (error) {
    console.log(error.message);     // 'Unexpected token...'
    console.log(error.name);        // 'SyntaxError'
} finally {
    console.log("Always runs");
}

// Throw a custom error
function divide(a, b) {
    if (b === 0) throw new Error("Cannot divide by zero");
    return a / b;
}


// =============================================================================
// CLASSES
// =============================================================================

// A class is a blueprint for creating objects
class Animal {
    // constructor runs when you do new Animal(...)
    constructor(name, sound) {
        this.name  = name;
        this.sound = sound;
    }

    // A method available on every instance
    speak() {
        return `${this.name} says ${this.sound}`;
    }

    // Static method — called on the class itself, not on instances
    static create(name, sound) {
        return new Animal(name, sound);
    }
}

const dog = new Animal("Rex", "Woof");
dog.speak();                    // 'Rex says Woof'
Animal.create("Cat", "Meow");  // calls the static method

// Inheritance — extend a parent class
class Dog extends Animal {
    constructor(name, breed) {
        super(name, "Woof");    // call the parent constructor
        this.breed = breed;
    }

    // Override a parent method
    speak() {
        return `${super.speak()} (${this.breed})`;
    }

    fetch() {
        return `${this.name} fetches the ball!`;
    }
}

const myDog = new Dog("Rex", "Labrador");
myDog.speak();      // 'Rex says Woof (Labrador)'
myDog.fetch();      // 'Rex fetches the ball!'


// =============================================================================
// MODULES (ES Modules)
// =============================================================================

// ---- math.js ----
// Named export — export multiple things from one file
export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }
export const PI = 3.14159;

// Default export — one main export per file
export default function multiply(a, b) { return a * b; }

// ---- app.js ----
// Named import — must match the exported name exactly
import { add, subtract, PI } from "./math.js";

// Import with an alias
import { add as addition } from "./math.js";

// Default import — you can name it anything
import multiply from "./math.js";

// Import everything as a namespace object
import * as Math2 from "./math.js";
Math2.add(1, 2);    // 3


// =============================================================================
// USEFUL ARRAY + OBJECT PATTERNS
// =============================================================================

// Chaining array methods
const result2 = [1, 2, 3, 4, 5, 6]
    .filter(n => n % 2 === 0)       // [2, 4, 6]
    .map(n => n * 10)               // [20, 40, 60]
    .reduce((acc, n) => acc + n, 0); // 120

// Object shorthand — when variable name matches the key name
const name3 = "Alice";
const age3  = 25;
const obj   = { name3, age3 };      // same as { name3: name3, age3: age3 }

// Computed property keys
const key  = "dynamicKey";
const obj2 = { [key]: "value" };    // { dynamicKey: 'value' }

// Swap two variables using destructuring
let a = 1, b = 2;
[a, b] = [b, a];                    // a = 2, b = 1

// Clone an array
const original = [1, 2, 3];
const clone    = [...original];

// Remove duplicates from an array using a Set
const dupes  = [1, 2, 2, 3, 3, 4];
const unique = [...new Set(dupes)]; // [1, 2, 3, 4]

// Convert an array of objects into a lookup map by id
const users = [{ id: 1, name: "Alice" }, { id: 2, name: "Bob" }];
const userMap = Object.fromEntries(users.map(u => [u.id, u]));
// { 1: { id: 1, name: 'Alice' }, 2: { id: 2, name: 'Bob' } }
