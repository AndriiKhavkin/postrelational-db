"""
ЛР1 (Postrelational DB): Демонстрація ООП на прикладі "3D Printer Farm".

Вимоги, які покриває цей файл:
- успадкування від абстрактного класу (AbstractPrinter);
- public / private властивості й методи (Python: _protected, __private);
- "перевантаження" методів (через @singledispatchmethod + альтернативні сигнатури);
- властивості простих типів (str, int, float, bool);
- посилання на інші об’єкти (PrintJob містить reference на FilamentProfile, PrinterFarm містить список принтерів);
- масиви/списки простих типів/об’єктів (history, queue, принтери, mesh);
- код створення об’єктів усіх класів + заповнення властивостей + виклик методів;

Запуск:
    python lab1_3d_printer_farm.py
Результат:
    - друк у консоль
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from functools import singledispatchmethod
from typing import List, Optional, Tuple
import random


# ----------------------------
# Допоміжні сутності (object references)
# ----------------------------

@dataclass
class FilamentProfile:
    """Профіль матеріалу (простий типи + сенсова модель)."""
    name: str
    material: str           # e.g. PLA, PETG, ABS
    nozzle_temp_c: int
    bed_temp_c: int
    density_g_cm3: float

    def describe(self) -> str:
        return (f"{self.name} ({self.material}): nozzle {self.nozzle_temp_c}°C, "
                f"bed {self.bed_temp_c}°C, density {self.density_g_cm3} g/cm³")


@dataclass
class PrintJob:
    """Завдання друку. Містить reference на FilamentProfile."""
    job_id: int
    model_name: str
    est_minutes: int
    filament: FilamentProfile
    gcode_lines: List[str]  # список простих типів (str)

    def summary(self) -> str:
        return (f"Job#{self.job_id}: {self.model_name}, "
                f"{self.est_minutes} min, filament={self.filament.material}")


# ----------------------------
# Абстрактний клас + наслідування
# ----------------------------

class AbstractPrinter(ABC):
    """
    Абстрактний 3D-принтер.
    Public: name, ip, is_busy, start(), stop(), get_status()
    Protected: _queue, _history
    Private: __secret_key, __last_calibration
    """

    def __init__(self, name: str, ip: str, max_queue: int = 3):
        # public properties (за конвенцією в Python — без підкреслення)
        self.name: str = name
        self.ip: str = ip
        self.is_busy: bool = False

        # protected properties (конвенція: один підкреслювач)
        self._queue: List[PrintJob] = []
        self._history: List[Tuple[str, str]] = []  # (timestamp, event)

        # private properties (name mangling: два підкреслювачі)
        self.__secret_key: str = f"{name}:{random.randint(1000, 9999)}"
        self.__last_calibration: Optional[datetime] = None

        self.max_queue = max_queue

    # ---- abstract + polymorphism
    @abstractmethod
    def technology(self) -> str:
        """Тип технології друку (FDM / Resin / etc.)"""
        raise NotImplementedError

    @abstractmethod
    def estimate_energy_kwh(self, job: PrintJob) -> float:
        """Оцінка енерговитрат на джобу."""
        raise NotImplementedError

    # ---- public methods
    def get_status(self) -> str:
        q = len(self._queue)
        last = self._history[-1][1] if self._history else "no events"
        return f"[{self.technology()}] {self.name} @ {self.ip} | busy={self.is_busy} | queue={q} | last='{last}'"

    def check_in(self) -> None:
        """Public method, яка використовує private method всередині."""
        token = self.__issue_token()
        self._log(f"check_in ok (token={token})")

    def calibrate(self) -> None:
        self.__last_calibration = datetime.now()
        self._log(f"calibrated at {self.__last_calibration.isoformat(timespec='seconds')}")

    def start(self) -> None:
        """Запуск друку першого джоба з черги."""
        if self.is_busy:
            self._log("start ignored: printer is already busy")
            return
        if not self._queue:
            self._log("start ignored: queue is empty")
            return

        job = self._queue.pop(0)
        self.is_busy = True
        energy = self.estimate_energy_kwh(job)
        self._log(f"START {job.summary()} | est_energy={energy:.2f} kWh")
        # симуляція виконання
        self._log(f"FINISH {job.model_name}")
        self.is_busy = False

    def stop(self, reason: str = "manual") -> None:
        self.is_busy = False
        self._log(f"STOP reason='{reason}'")

    # ---- "перевантаження" (overloaded methods) via singledispatchmethod
    @singledispatchmethod
    def enqueue(self, job) -> None:
        """Fallback для невідомих типів."""
        raise TypeError(f"enqueue() does not support type: {type(job)!r}")

    @enqueue.register
    def _(self, job: PrintJob) -> None:
        """Додає один PrintJob."""
        if len(self._queue) >= self.max_queue:
            self._log(f"enqueue rejected: queue is full (max={self.max_queue})")
            return
        self._queue.append(job)
        self._log(f"enqueued {job.summary()}")

    @enqueue.register
    def _(self, jobs: list) -> None:
        """Додає список PrintJob."""
        # сувора перевірка, щоб "мало сенс"
        if not all(isinstance(j, PrintJob) for j in jobs):
            raise TypeError("enqueue(list) expects a list[PrintJob]")
        for j in jobs:
            self.enqueue(j)  # перевикористовуємо логіку enqueue(PrintJob)

    @enqueue.register
    def _(self, gcode: str) -> None:
        """
        Перевантаження №3: можна передати "швидкий" gcode як str,
        і принтер сам сформує PrintJob для сервісного прогону.
        """
        job = PrintJob(
            job_id=random.randint(9000, 9999),
            model_name="ServiceMacro",
            est_minutes=2,
            filament=FilamentProfile("ServicePLA", "PLA", 200, 60, 1.24),
            gcode_lines=gcode.splitlines() if gcode.strip() else ["G28", "M84"],
        )
        self.enqueue(job)

    # ---- protected + private methods
    def _log(self, event: str) -> None:
        ts = datetime.now().isoformat(timespec="seconds")
        self._history.append((ts, event))

    def _get_history(self) -> List[Tuple[str, str]]:
        """Protected accessor: віддамо список подій для аналізу/візуалізації."""
        return list(self._history)

    def __issue_token(self) -> str:
        """Private method."""
        # умовно імітуємо токен авторизації/сесії
        return f"TKN-{hash(self.__secret_key) % 100000:05d}"


# ----------------------------
# Конкретні принтери
# ----------------------------

class FDMPrinter(AbstractPrinter):
    """FDM-принтер (нитка)."""

    def __init__(self, name: str, ip: str, nozzle_diam_mm: float, bed_size_mm: Tuple[int, int]):
        super().__init__(name, ip, max_queue=4)
        self.nozzle_diam_mm = nozzle_diam_mm          # simple type
        self.bed_size_mm = bed_size_mm                # tuple of simple types
        self.bed_mesh: List[List[float]] = []         # array/list of simple types
        self._generate_fake_mesh()

    def technology(self) -> str:
        return "FDM"

    def estimate_energy_kwh(self, job: PrintJob) -> float:
        # груба оцінка: хвилини * коефіцієнт (в середньому 0.08 кВт·год / год)
        return (job.est_minutes / 60.0) * 0.08

    def _generate_fake_mesh(self, n: int = 9) -> None:
        """Сервісний метод: генерує фейковий bed-mesh, щоб було що візуалізувати."""
        base = random.uniform(-0.15, 0.15)
        self.bed_mesh = [
            [base + random.uniform(-0.08, 0.08) for _ in range(n)]
            for __ in range(n)
        ]
        self._log(f"bed_mesh generated ({n}x{n})")

    # додатковий public метод
    def relevel(self) -> None:
        self._generate_fake_mesh()
        self._log("relevel done")


class ResinPrinter(AbstractPrinter):
    """SLA/MSLA-принтер (смола)."""

    def __init__(self, name: str, ip: str, lcd_px: Tuple[int, int]):
        super().__init__(name, ip, max_queue=2)
        self.lcd_px = lcd_px                   # simple type tuple
        self.vat_volume_ml: int = 500          # simple type
        self.cleaning_cycles: List[int] = []   # list of simple types

    def technology(self) -> str:
        return "Resin"

    def estimate_energy_kwh(self, job: PrintJob) -> float:
        # смола зазвичай менше підігріває bed, але довше світить UV
        return (job.est_minutes / 60.0) * 0.05

    def run_cleaning(self, minutes: int) -> None:
        self.cleaning_cycles.append(minutes)
        self._log(f"cleaning cycle {minutes} min")


# ----------------------------
# Ферма (aggregator object references + lists)
# ----------------------------

class PrinterFarm:
    def __init__(self, name: str):
        self.name = name
        self.printers: List[AbstractPrinter] = []     # list of objects
        self.queue: List[PrintJob] = []               # shared job pool

        self.__admin_pin = "0420"                     # private property

    def add_printer(self, printer: AbstractPrinter) -> None:
        self.printers.append(printer)

    def submit_job(self, job: PrintJob) -> None:
        self.queue.append(job)

    def dispatch(self) -> None:
        """
        Простий планувальник: розкидає джоби з загальної черги по принтерах.
        Демонструє роботу з поліморфізмом (AbstractPrinter у списку).
        """
        while self.queue:
            job = self.queue.pop(0)
            # вибираємо принтер з найменшою локальною чергою
            target = min(self.printers, key=lambda p: len(p._queue))
            target.enqueue(job)

    def authenticate_admin(self, pin: str) -> bool:
        """Public method, який читає private property."""
        ok = pin == self.__admin_pin
        return ok

    def utilization_report(self) -> List[Tuple[str, int]]:
        """Для візуалізації: скільки подій 'START' було на кожному принтері."""
        report = []
        for p in self.printers:
            starts = sum(1 for _, e in p._get_history() if e.startswith("START"))
            report.append((p.name, starts))
        return report


# ----------------------------
# Візуалізація
# ----------------------------

def print_bed_mesh_ascii(printer):
    print(f"\nBed mesh for {printer.name} (mm):")
    for row in printer.bed_mesh:
        print(" ".join(f"{v:+.2f}" for v in row))

def print_utilization_ascii(farm):
    print("\nPrinter utilization:")
    for name, count in farm.utilization_report():
        bar = "█" * count
        print(f"{name:20} | {bar} ({count})")



# ----------------------------
# Demo: створення об'єктів усіх класів + виклики методів
# ----------------------------

def demo() -> None:
    print("=== 3D Printer Farm OOP Demo (ЛР1) ===\n")

    # 1) створюємо профілі філаменту
    pla = FilamentProfile("Generic PLA", "PLA", 205, 60, 1.24)
    petg = FilamentProfile("PETG Black", "PETG", 240, 80, 1.27)

    print("Filament profiles:")
    print(" -", pla.describe())
    print(" -", petg.describe())
    print()

    # 2) створюємо джоби
    job1 = PrintJob(1, "KPI_CalibrationCube.stl", 25, pla, ["G28", "G29", "M104 S205"])
    job2 = PrintJob(2, "EnclosureFanDuct.stl", 90, petg, ["G28", "M104 S240", "M190 S80"])
    job3 = PrintJob(3, "CaseBracket.stl", 55, pla, ["G28", "M104 S205", "M140 S60"])
    job4 = PrintJob(4, "Resin_LogoBadge.ctb", 75, FilamentProfile("Basic Resin", "Resin", 0, 0, 1.10), ["; sliced file"])

    # 3) створюємо принтери (успадкування від AbstractPrinter)
    k1max = FDMPrinter("Creality K1 Max", "192.168.0.41", nozzle_diam_mm=0.4, bed_size_mm=(300, 300))
    ender = FDMPrinter("Ender 3 KE", "192.168.0.42", nozzle_diam_mm=0.4, bed_size_mm=(220, 220))
    resin = ResinPrinter("Anycubic Photon", "192.168.0.77", lcd_px=(2560, 1620))

    # 4) виклики public/private/protected логіки
    k1max.check_in()
    k1max.calibrate()
    k1max.relevel()  # додатковий метод підкласу

    resin.check_in()
    resin.run_cleaning(6)

    # 5) створюємо ферму і додаємо принтери (посилання на об’єкти)
    farm = PrinterFarm("KPI Mini-Farm")
    farm.add_printer(k1max)
    farm.add_printer(ender)
    farm.add_printer(resin)

    # 6) додаємо джоби в спільну чергу ферми
    farm.submit_job(job1)
    farm.submit_job(job2)
    farm.submit_job(job3)
    farm.submit_job(job4)

    # 7) "перевантаження": enqueue(PrintJob), enqueue(list[PrintJob]), enqueue(str)
    #    a) str — швидкий сервісний макрос
    ender.enqueue("G28\nM84")

    #    b) list[PrintJob] — напряму кинули список на принтер
    k1max.enqueue([PrintJob(10, "QuickClip.stl", 12, pla, ["G28", "M104 S205"])])

    #    c) dispatch: розкидання job pool по принтерах
    farm.dispatch()

    # 8) Статуси
    print("Statuses after dispatch:")
    for p in farm.printers:
        print(" -", p.get_status())
    print()

    # 9) старт друку (виклик поліморфних методів)
    print("Running jobs:")
    for p in farm.printers:
        # спробуємо стартнути два рази, щоб показати логіку черги
        p.start()
        p.start()
    print()

    # 10) простий приклад приватного доступу (admin pin)
    print("Admin auth:")
    print(" - pin 0000:", farm.authenticate_admin("0000"))
    print(" - pin 0420:", farm.authenticate_admin("0420"))
    print()


    # 11) вивід
    print_bed_mesh_ascii(k1max)
    print_utilization_ascii(farm)

    # 12) покажемо кілька останніх подій (list of simple types inside tuples)
    print("Last events (K1 Max):")
    for ts, ev in k1max._get_history()[-6:]:
        print(f"   {ts} | {ev}")


if __name__ == "__main__":
    demo()
