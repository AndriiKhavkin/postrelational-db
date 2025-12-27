Class lr4.Printer Extends (%Persistent, lr4.Device)
{
    Property ModelName As %String(MAXLEN = 100);
    
    Property Status As %String;
    
    Property ConfigSettings As Array Of %String;
    
    Property PhysicalLocation As lr4.Location;
    
    /// ALWAYS computed property (Calculated) + getter
    Property LocationLabel As %String [ Calculated ];
    
    Relationship Jobs As lr4.PrintJob [ Cardinality = children, Inverse = PrinterParent ];
    
    Index InvNumIdx On InventoryNumber [ Unique ];

    Method LocationLabelGet() As %String
    {
        If '$IsObject(..PhysicalLocation) Quit ""

        Set room = ..PhysicalLocation.RoomNumber
        Set shelf = ..PhysicalLocation.ShelfIndex

        If (room=""),(shelf="") Quit ""
        Quit "Room "_room_", Shelf "_shelf
    }
}
