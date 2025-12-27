Class lr5.Generator
{

ClassMethod Populate(
    techCount As %Integer = 5,
    printerCount As %Integer = 3,
    jobsPerPrinter As %Integer = 4,
    wipe As %Boolean = 1
) As %Status
{
    Set sc = $$$OK
    Try {
        If wipe {
            // Order is important because of parent-child relationship
            Do ##class(lr4.PrintJob).%KillExtent()
            Do ##class(lr4.Printer).%KillExtent()
            Do ##class(lr4.Technician).%KillExtent()
        }

        // --------- 1) TECHNICIANS ----------
        Set techIds = ##class(%ListOfDataTypes).%New()
        For i=1:1:techCount {
            Set t = ##class(lr4.Technician).%New()
            Set t.FullName = "Tech_"_##class(%PopulateUtils).String(6)
            Set t.BadgeID = "T-"_i_"-"_$Random(10000)
            Set sc = t.%Save()
            If $$$ISERR(sc) Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
            Do techIds.Insert(t.%Id())
        }

        // Some sample data pools
        Set models = "Prusa,Creality K1 Max,Ender 3 KE,Bambu P1P"
        Set statuses = "Idle,Active,Paused,Error"
        Set materials = "PLA,PETG,ABS,TPU"

        // --------- 2) PRINTERS + JOBS ----------
        Set globalJobId = 1000

        For pIndex=1:1:printerCount {
            Set p = ##class(lr4.Printer).%New()

            // Device fields
            Set p.InventoryNumber = "INV-"_pIndex_"-"_##class(%PopulateUtils).String(5)
            Set p.PurchaseDate = +$Horolog - $Random(3000)

            // Printer fields
            Set p.ModelName = $Piece(models,",",$Random(4)+1)
            Set p.Status = $Piece(statuses,",",$Random(4)+1)

            // Serial object location
            Set p.PhysicalLocation = ##class(lr4.Location).%New()
            Set p.PhysicalLocation.RoomNumber = ""_(100+$Random(50))
            Set p.PhysicalLocation.ShelfIndex = $Char(65+$Random(6)) // A..F

            // Array config
            Do p.ConfigSettings.SetAt($Piece(materials,",",$Random(4)+1), "Material")
            Do p.ConfigSettings.SetAt((40+$Random(101)), "Speed") // 40..140
            Do p.ConfigSettings.SetAt((190+$Random(71)), "BedTemp") // 190..260

            // Create children jobs
            For j=1:1:jobsPerPrinter {
                Set job = ##class(lr4.PrintJob).%New()
                Set job.JobID = globalJobId  Set globalJobId = globalJobId + 1
                Set job.FileName = "model_"_##class(%PopulateUtils).String(6)_".gcode"
                Set job.NozzleTemp = 180 + $Random(101) // 180..280

                // Reference: random technician
                Set rnd = $Random(techIds.Count())+1
                Set techId = techIds.GetAt(rnd)
                Set job.OperatorRef = ##class(lr4.Technician).%OpenId(techId)

                // Relationship parent
                Set job.PrinterParent = p

                // List tags
                Set job.Tags = ##class(%ListOfDataTypes).%New()
                Do job.Tags.Insert("auto")
                If ($Random(2)=1) Do job.Tags.Insert("urgent")
                If ($Random(3)=1) Do job.Tags.Insert("night-shift")

                // Stream GCodeData
                Set job.GCodeData = ##class(%GlobalCharacterStream).%New()
                Do job.GCodeData.Write("G28 ; home"_$C(13,10))
                Do job.GCodeData.Write("G1 Z5 F3000"_$C(13,10))
                Do job.GCodeData.Write("M104 S"_job.NozzleTemp_" ; set nozzle temp"_$C(13,10))

                // Insert child into parent's children collection (safe way)
                Do p.Jobs.Insert(job)
            }

            // Save parent (should cascade save children)
            Set sc = p.%Save()
            If $$$ISERR(sc) Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        }

        Write !,"[OK] Generated: ",techCount," technicians, ",printerCount," printers, ",(printerCount*jobsPerPrinter)," jobs."
    }
    Catch ex {
        Set sc = ex.AsStatus()
        Write !,"[ERROR] ",$System.Status.GetErrorText(sc)
    }

    Quit sc
}

}
