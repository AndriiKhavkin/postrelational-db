Class lr4.Utils
{

/// Метод для генерації даних (з попереднього кроку)
ClassMethod Run()
{
    // ... (код з попереднього повідомлення залишається без змін) ...
    // Для зручності, я скопіюю скорочену версію генерації нижче, 
    // але якщо у вас вже є Run(), просто додайте метод Report.
    
    Do ##class(lr4.Printer).%KillExtent()
    Do ##class(lr4.Technician).%KillExtent()
    
    // 1. Technicians
    Set t1 = ##class(lr4.Technician).%New()
    Set t1.FullName="Oleksandr", t1.BadgeID="T-01" 
    Do t1.%Save()
    
    // 2. Printer & Jobs
    Set p1 = ##class(lr4.Printer).%New()
    Set p1.InventoryNumber="INV-1", p1.ModelName="Prusa", p1.Status="Active"
    Set p1.PhysicalLocation.RoomNumber="101", p1.PhysicalLocation.ShelfIndex="A"
    Do p1.ConfigSettings.SetAt("PLA", "Material")
    
    Set j1 = ##class(lr4.PrintJob).%New()
    Set j1.JobID=100, j1.OperatorRef=t1, j1.PrinterParent=p1, j1.NozzleTemp=210
    Do j1.Tags.Insert("Urgent")
    Do j1.GCodeData.Write("G28; Home"_$C(13,10)_"G1 Z5")
    
    Do p1.%Save()
    Write "Data Generated.",!
}

/// Метод для відображення звіту
ClassMethod Report()
{
    Write !, "========================================="
    Write !, "       3D PRINTER FARM REPORT"
    Write !, "=========================================",!

    // --- 1. СПИСОК ТЕХНІКІВ (Reference Class) ---
    Write !, "--- TECHNICIANS ---"
    Set sql = "SELECT ID FROM lr4.Technician"
    Set rs = ##class(%SQL.Statement).%ExecDirect(,sql)
    
    While rs.%Next() {
        Set tech = ##class(lr4.Technician).%OpenId(rs.ID)
        Write !, " ["_tech.BadgeID_"] "_tech.FullName
    }
    Write !, "-------------------",!

    // --- 2. ПРИНТЕРИ ТА ЇХ ЗАВДАННЯ ---
    // Використовуємо %OpenId для доступу до колекцій та зв'язків
    Set sql = "SELECT ID FROM lr4.Printer"
    Set rs = ##class(%SQL.Statement).%ExecDirect(,sql)

    While rs.%Next() {
        Set p = ##class(lr4.Printer).%OpenId(rs.ID)

        Write !, "PRINTER: ", p.ModelName
        Write !, " > Inv#:     ", p.InventoryNumber, " (Purchased: ", $ZDate(p.PurchaseDate, 3), ")"
        Write !, " > Status:   ", p.Status
        
        // Відображення Serial Object (Location)
        Write !, " > Location: Room ", p.PhysicalLocation.RoomNumber, ", Shelf ", p.PhysicalLocation.ShelfIndex
        
        // Відображення Array Collection (Settings)
        Write !, " > Config:"
        Set key = ""
        Do {
            Set val = p.ConfigSettings.GetNext(.key)
            If key'="" Write "   - ", key, ": ", val,!
        } While (key'="")

        // --- ВІДОБРАЖЕННЯ ДОЧІРНІХ ЗАВДАНЬ (Parent-Child) ---
        Write !, " > ACTIVE JOBS:"
        Set key = ""
        Do {
            Set job = p.Jobs.GetNext(.key)
            If (job '= "") {
                Write !, "    JOB #", job.JobID, " (", job.FileName, ")"
                Write !, "      * Temp: ", job.NozzleTemp, "C"
                
                // Reference (посилання на об'єкт техніка)
                If $IsObject(job.OperatorRef) {
                    Write !, "      * Operator: ", job.OperatorRef.FullName
                }

                // List Collection (Tags)
                Write !, "      * Tags: "
                For i=1:1:job.Tags.Count() {
                    Write job.Tags.GetAt(i), " "
                }

                // Stream (GCode) - читаємо перші 50 символів для прев'ю
                Write !, "      * GCode Preview: "
                Do job.GCodeData.Rewind() // Повертаємось на початок потоку
                Write $Replace(job.GCodeData.Read(50), $C(13,10), " "), "..." 
                Write !
            }
        } While (key '= "")
        
        Write !, "-----------------------------------------"
    }
}

}
