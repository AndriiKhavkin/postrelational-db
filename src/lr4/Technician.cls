Class lr4.Technician Extends %Persistent
{
    Property FullName As %String [ Required ];
    
    Property BadgeID As %String [ Required ];
    
    Index BadgeIdx On BadgeID [ Unique ];
}