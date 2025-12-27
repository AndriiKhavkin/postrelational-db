<!-- ![alt text](image.png) -->

# Practice 3


## Inheritance from abstract class:

The Printer class inherits from the Device abstract class.

Logic: In the future, you might have scanners or laser cutters that will also have an inventory number (InventoryNumber), so this property is moved to a common abstract parent.

## Single literal properties:

Properties like Status, FileName, PurchaseDate, etc.

## Reference (from one class to another):

The OperatorRef property in the PrintJob class.

Logic: A job refers to a technician (Technician). This is not a Parent-Child relationship because if a job is deleted, the technician record must remain in the database.

## Built-in object (Serial object):

The Location class (used as the PhysicalLocation property in Printer).

Logic: We do not need a separate table for locations. We store the "Room" and "Shelf" data directly inside the printer record (embedded).

## Collection-list:

The Tags property in the PrintJob class.

Type: List Of %String.

Example: ("urgent", "prototype", "PETG").

## Collection-array:

The ConfigSettings property in the Printer class.

Type: Array Of %String.

Logic: Key-Value pairs for configuration. For example: Settings("FanSpeed") = "100%", Settings("Network") = "Static".

## Character or binary stream:

The GCodeData property in the PrintJob class.

Type: GlobalCharacterStream.

Logic: G-code files (instructions for the printer) can be very large (tens of megabytes), so a standard String type is insufficient; a stream is required.

## One-many and Parent-Children relationships:

Parent-Child: Printer (Parent) <-> PrintJob (Child).

If we decommission a printer (delete the object), its print queue (PrintJob) should also be deleted. In IRIS, this means PrintJob data is physically stored within the Printer global.

One-Many (Reference): Technician (One) <-> PrintJob (Many). One technician can initiate multiple jobs.

## Required & Unique:

Device.InventoryNumber: Unique (The inventory number cannot be duplicated).

Technician.FullName: Required (A technician must have a name).

## Constraints (Value limits):

Printer.ModelName: MaxLen = 100 (String length limit).

PrintJob.NozzleTemp: MinVal = 180, MaxVal = 280 (The nozzle temperature cannot be lower than the melting point or higher than the safety limit).
