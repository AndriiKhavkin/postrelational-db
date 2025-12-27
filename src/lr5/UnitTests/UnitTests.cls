Class lr5.UnitTests Extends %UnitTest.TestCase
{

Method CleanAll()
{
    // Ensure clean DB for each test (important for Unique constraints)
    Do ##class(lr4.PrintJob).%KillExtent()
    Do ##class(lr4.Printer).%KillExtent()
    Do ##class(lr4.Technician).%KillExtent()
}

Method OnBeforeEachTest()
{
    Do ..CleanAll()
}

Method OnAfterEachTest()
{
    Do ..CleanAll()
}

/// 1) Test creation of object (Printer + Location + Job + Technician)
Method TestCreationOK()
{
    Set t = ##class(lr4.Technician).%New()
    Set t.FullName="Test Tech"
    Set t.BadgeID="BADGE-001"
    Do $$$AssertStatusOK(t.%Save(), "Technician should save")

    Set p = ##class(lr4.Printer).%New()
    Set p.InventoryNumber="INV-TEST-001"
    Set p.PurchaseDate=+$Horolog
    Set p.ModelName="Creality K1 Max"
    Set p.Status="Idle"
    Set p.PhysicalLocation = ##class(lr4.Location).%New()
    Set p.PhysicalLocation.RoomNumber="101"
    Set p.PhysicalLocation.ShelfIndex="A"

    Set job = ##class(lr4.PrintJob).%New()
    Set job.JobID=1
    Set job.NozzleTemp=210
    Set job.OperatorRef=t
    Set job.PrinterParent=p
    Set job.GCodeData=##class(%GlobalCharacterStream).%New()
    Do job.GCodeData.Write("G28")
    Do p.Jobs.Insert(job)

    Do $$$AssertStatusOK(p.%Save(), "Printer (with child job) should save")

    // Check computed property works (getter)
    Do $$$AssertEquals(p.LocationLabel, "Room 101, Shelf A", "Computed LocationLabel should match")
}

/// 2) Test Required property: InventoryNumber (Device -> Printer)
Method TestRequiredInventoryNumber()
{
    Set p = ##class(lr4.Printer).%New()
    Set p.ModelName="No Inv"
    Set sc = p.%Save()

    Do $$$AssertStatusNotOK(sc, "Printer without InventoryNumber must fail (Required)")
}

/// 3) Test Unique property: InventoryNumber
Method TestUniqueInventoryNumber()
{
    Set p1 = ##class(lr4.Printer).%New()
    Set p1.InventoryNumber="INV-UNIQ-001"
    Do $$$AssertStatusOK(p1.%Save(), "First printer must save")

    Set p2 = ##class(lr4.Printer).%New()
    Set p2.InventoryNumber="INV-UNIQ-001"
    Set sc = p2.%Save()

    Do $$$AssertStatusNotOK(sc, "Second printer with same InventoryNumber must fail (Unique)")
}

/// 4) Test Required + Unique: Technician.BadgeID and FullName
Method TestTechnicianRequiredAndUnique()
{
    // Required FullName / BadgeID
    Set tBad = ##class(lr4.Technician).%New()
    Set tBad.BadgeID="B-1"
    Set sc = tBad.%Save()
    Do $$$AssertStatusNotOK(sc, "Technician without FullName must fail")

    // Unique BadgeID
    Set t1 = ##class(lr4.Technician).%New()
    Set t1.FullName="Tech 1"
    Set t1.BadgeID="B-UNIQ"
    Do $$$AssertStatusOK(t1.%Save(), "Technician 1 must save")

    Set t2 = ##class(lr4.Technician).%New()
    Set t2.FullName="Tech 2"
    Set t2.BadgeID="B-UNIQ"
    Set sc = t2.%Save()
    Do $$$AssertStatusNotOK(sc, "Duplicate BadgeID must fail (Unique)")
}

/// 5) Test constraint: PrintJob.NozzleTemp MIN/MAX
Method TestNozzleTempConstraint()
{
    Set t = ##class(lr4.Technician).%New()
    Set t.FullName="Tech"
    Set t.BadgeID="B-1"
    Do t.%Save()

    Set p = ##class(lr4.Printer).%New()
    Set p.InventoryNumber="INV-1"
    Do p.%Save()

    Set job = ##class(lr4.PrintJob).%New()
    Set job.JobID=1
    Set job.PrinterParent=p
    Set job.OperatorRef=t

    // invalid: 300 > 280
    Set job.NozzleTemp=300
    Set sc = job.%Save()
    Do $$$AssertStatusNotOK(sc, "NozzleTemp 300 must fail (MaxVal 280)")
}

/// 6) Test behavior when deleting object with children relationship (Printer -> Jobs)
Method TestCascadeDeletePrinterJobs()
{
    Set t = ##class(lr4.Technician).%New()
    Set t.FullName="Tech"
    Set t.BadgeID="B-1"
    Do t.%Save()

    Set p = ##class(lr4.Printer).%New()
    Set p.InventoryNumber="INV-CASCADE"
    Set p.PhysicalLocation=##class(lr4.Location).%New()
    Set p.PhysicalLocation.RoomNumber="200"
    Set p.PhysicalLocation.ShelfIndex="B"

    For i=1:1:3 {
        Set job = ##class(lr4.PrintJob).%New()
        Set job.JobID=100+i
        Set job.NozzleTemp=200
        Set job.OperatorRef=t
        Set job.PrinterParent=p
        Do p.Jobs.Insert(job)
    }

    Do $$$AssertStatusOK(p.%Save(), "Printer with 3 child jobs must save")

    // capture one child id to verify delete
    Set key=""
    Set child = p.Jobs.GetNext(.key)
    Set childId = child.%Id()
    Do $$$AssertTrue(##class(lr4.PrintJob).%ExistsId(childId), "Child job must exist before delete")

    Set pid = p.%Id()
    Do ##class(lr4.Printer).%DeleteId(pid)
    
    Do $$$AssertEquals(##class(lr4.Printer).%ExistsId(pid), 0, "Printer must be deleted")
    Do $$$AssertEquals(##class(lr4.PrintJob).%ExistsId(childId), 0, "Child job must be deleted with parent (Cascade)")

}

/// 7) Test deletion of object (simple delete)
Method TestDeleteTechnician()
{
    Set t = ##class(lr4.Technician).%New()
    Set t.FullName="Delete Me"
    Set t.BadgeID="DEL-1"
    Do $$$AssertStatusOK(t.%Save(), "Technician must save")

    Set tid = t.%Id()
    Do ##class(lr4.Technician).%DeleteId(tid)
    Do $$$AssertEquals(##class(lr4.Technician).%ExistsId(tid), 0, "Technician must be deleted")

}

}
