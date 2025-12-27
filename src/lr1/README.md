# Practice 1 (OOP)

## Topic
Object-Oriented Programming concepts demonstration using a **3D Printer Farm** domain model.

## Goal
Design a program in a high-level programming language that demonstrates the core concepts of Object-Oriented Programming (OOP).  
The program must be logically structured, consistent, and all classes, objects, properties, and methods must have a clear practical meaning.

## Description
The laboratory work implements a simplified model of a **3D printer farm**, which includes different types of printers, print jobs, material profiles, and a job dispatcher.  
The system demonstrates inheritance, encapsulation, polymorphism, object references, and collections without using any external libraries.

The implementation is written in **Python** and does not require additional dependencies.

## Implemented OOP Concepts

### 1. Inheritance from an Abstract Class
- An abstract base class `AbstractPrinter` defines the common interface and behavior for all printers.
- Concrete printer classes inherit from it:
  - `FDMPrinter`
  - `ResinPrinter`

### 2. Public and Private Properties and Methods
- **Public members**: printer name, IP address, status, job control methods.
- **Protected members**: job queue, event history.
- **Private members**: internal authentication data and service methods.

### 3. Method Overloading
- The `enqueue()` method is overloaded to support:
  - a single print job;
  - a list of print jobs;
  - a service G-code command represented as a string.

### 4. Properties of Different Types
- Simple data types:
  - `int`, `float`, `bool`, `str`
- Composite types:
  - `tuple`, `list`
- Examples include temperatures, dimensions, identifiers, and configuration values.

### 5. References to Other Objects
- A `PrintJob` object contains a reference to a `FilamentProfile`.
- A `PrinterFarm` object stores references to multiple printer objects.

### 6. Arrays and Lists
- Lists of print jobs, printers, event logs, and calibration mesh data are used throughout the system.

### 7. Object Creation and Method Invocation
- All classes are instantiated in the demo scenario.
- All properties are populated with meaningful values.
- All public methods are called to demonstrate behavior and interaction between objects.

## Text-Based Visualization
To avoid external dependencies, visualization is implemented in **ASCII format**:
- Printer bed leveling mesh is displayed as a numeric table.
- Printer utilization is shown as a text-based bar chart.

This approach ensures portability and simplicity while preserving clarity.

## Execution
Run the program from the project root:

```bash
python src/lr1/main.py
