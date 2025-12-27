Class lr2.PrinterFarmGlobal Extends %RegisteredObject
{

/// ЛР2: Глобали + списки + вбудовані функції для роботи зі списками ($LIST*)
/// Глобал має 4 підіндекси 3 різних типів:
///   1) printerId  - число
///   2) printDate  - дата (зберігаємо як $ZDATEH -> число)
///   3) material   - рядок
///   4) jobId      - число
///
/// Значення вузла містить ОБИДВА типи списків:
///   - tempsList: $LIST, зібраний через $LISTBUILD (binary list)
///   - tagsList : $LIST, зібраний через $LISTFROMSTRING (list from string)
///
/// Показуємо використання щонайменше 4 built-in функцій для списків:
///   $LISTLENGTH, $LISTGET, $LISTFIND, $LISTTOSTRING
///
/// Всі параметри читаємо з пристрою введення (READ).

ClassMethod Run()
{
    Write !,"=== LR2: Printer Farm Global + Lists Demo ===",!

    // --- 1) Зчитуємо 4 підіндекси (3 типи: числа, дата, рядок)
    Read !,"1) Enter Printer ID (Number, e.g., 41): ", printerId
    Read !,"2) Enter Print Date (YYYY-MM-DD): ", dateStr
    Set dateH = $ZDateH(dateStr, 3)  // date -> integer (days since 1840-12-31)
    Read !,"3) Enter Material (String, e.g., PLA/PETG): ", material
    Read !,"4) Enter Job ID (Number, e.g., 1001): ", jobId

    // --- 2) Додаткові параметри (також зчитуємо з input)
    Write !,"--- Job Details ---",!
    Read !,"Model name (String): ", modelName
    Read !,"Estimated minutes (Number): ", estMinutes
    Read !,"Nozzle temp (C, Number): ", nozzleTemp
    Read !,"Bed temp (C, Number): ", bedTemp
    Read !,"Tags (comma-separated, e.g., 'kpi,test,prototype'): ", tagsCsv

    // --- 3) Формуємо ОБИДВА типи списків
    // (A) $LISTBUILD: "binary list" (кодується у $LIST формат)
    Set tempsList = $ListBuild(nozzleTemp, bedTemp)

    // (B) $LISTFROMSTRING: будуємо $LIST зі строки з роздільниками
    //     За замовчуванням розділювач кома, але краще явно: ","
    Set tagsList  = $ListFromString(tagsCsv, ",")

    // --- 4) Запис у глобал (4 підіндекси)
    // Збережемо як один $LIST, що містить прості значення + 2 вкладені $LIST
    Set value = $ListBuild(modelName, estMinutes, tempsList, tagsList)

    Set ^PrinterJobs(printerId, dateH, material, jobId) = value

    Write !,"Saved to global ^PrinterJobs(",printerId,",",dateStr,",",material,",",jobId,")",!

    // --- 5) Демонстрація 4+ built-in функцій для списків ($LIST*)
    Write !,"", "=== Built-in list functions demo ===",!

    // 5.1) $LISTLENGTH
    Set v = ^PrinterJobs(printerId, dateH, material, jobId)
    Set vLen = $ListLength(v)
    Write !,"$LISTLENGTH(value) = ", vLen, " (top-level fields)",!

    // 5.2) $LISTGET
    Set readModel = $ListGet(v, 1)
    Set readMinutes = $ListGet(v, 2)
    Write !,"$LISTGET(value,1) model     = ", readModel,!
    Write !,"$LISTGET(value,2) minutes   = ", readMinutes,!

    // Дістанемо вкладений tempsList і покажемо $LISTGET по ньому
    Set readTemps = $ListGet(v, 3)
    Write !,"NozzleTemp = ", $ListGet(readTemps, 1), " C",!
    Write "BedTemp    = ", $ListGet(readTemps, 2), " C",!

    // 5.3) $LISTFIND: пошук тегу у tagsList
    Set readTags = $ListGet(v, 4)
    Read !,"", "Enter tag to search (String): ", tagToFind
    Set pos = $ListFind(readTags, tagToFind)
    If pos>0 {
        Write "Tag '", tagToFind, "' FOUND at position ", pos,!
    } Else {
        Write "Tag '", tagToFind, "' NOT found",!
    }

    // 5.4) $LISTTOSTRING: показ списку тегів у вигляді строки
    Set tagsAsString = $ListToString(readTags, ",")
    Write !,"$LISTTOSTRING(tagsList) = ", tagsAsString,!

    // Додатково (не обов'язково, але корисно): покажемо $ORDER (обхід підіндексів)
    Write !,"=== Quick scan by $ORDER (show jobs for this Printer+Date) ===",!
    Set mat=""
    For {
        Set mat = $Order(^PrinterJobs(printerId, dateH, mat))
        Quit:mat=""
        Set j=""
        For {
            Set j = $Order(^PrinterJobs(printerId, dateH, mat, j))
            Quit:j=""
            Set vv = ^PrinterJobs(printerId, dateH, mat, j)
            Write " - material=", mat, " jobId=", j, " model=", $ListGet(vv,1), " tags=", $ListToString($ListGet(vv,4), ","),!
        }
    }

    Write !,"Done.",!
}

}
