Class lr4.PrintJob Extends %Persistent
{
    Property JobID As %Integer [ Required ];
    
    Property FileName As %String;
    
    Property NozzleTemp As %Integer(MAXVAL = 280, MINVAL = 180);
    
    Property GCodeData As %GlobalCharacterStream;
    
    Property Tags As List Of %String;
    
    Property OperatorRef As lr4.Technician;
    
    Relationship PrinterParent As lr4.Printer [ Cardinality = parent, Inverse = Jobs ];
}
