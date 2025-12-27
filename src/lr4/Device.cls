Class lr4.Device [ Abstract ]
{
    Property InventoryNumber As %String [ Required ];
    
    Property PurchaseDate As %Date;

    Index InvNumIdx On InventoryNumber [ Unique ];
}