CHROMATIC_SHARPS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
CHROMATIC_FLATS = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

FLAT_KEYS = {"F", "Bb", "Eb", "Ab", "Db", "Gb", "Dm", "Gm", "Cm", "Fm", "Bbm", "Ebm"}

NOTE_TO_VALUE = {}
for i, name in enumerate(CHROMATIC_SHARPS):
    NOTE_TO_VALUE[name] = i
for i, name in enumerate(CHROMATIC_FLATS):
    NOTE_TO_VALUE[name] = i


# --- Intervalos (em semitons) ---

INTERVALS = {
    "unissono": 0,
    "segunda menor": 1,
    "segunda maior": 2,
    "terça menor": 3,
    "terça maior": 4,
    "quarta justa": 5,
    "quarta aumentada": 6,
    "quinta diminuta": 6,
    "quinta justa": 7,
    "quinta aumentada": 8,
    "sexta menor": 8,
    "sexta maior": 9,
    "sétima menor": 10,
    "sétima maior": 11,
    "oitava": 12,
    "nona menor": 13,
    "nona maior": 14,
    "décima primeira justa": 17,
    "décima terceira maior": 21,
}

T = 2   # tom
S = 1   # semitom


# --- Escalas (sequências de intervalos em semitons) ---

SCALE_FORMULAS = {
    "maior": [T, T, S, T, T, T, S],
    "menor natural": [T, S, T, T, S, T, T],
    "menor harmônica": [T, S, T, T, S, T+S, S],
    "menor melódica": [T, S, T, T, T, T, S],
    "pentatônica maior": [T, T, T+S, T, T+S],
    "pentatônica menor": [T+S, T, T, T+S, T],
    "blues": [T+S, T, S, S, T+S, T],
    "cromática": [S] * 12,
    "dórica": [T, S, T, T, T, S, T],
    "frígia": [S, T, T, T, S, T, T],
    "lídia": [T, T, T, S, T, T, S],
    "mixolídia": [T, T, S, T, T, S, T],
    "lócria": [S, T, T, S, T, T, T],
}


# --- Acordes (intervalos a partir da tônica, em semitons) ---

CHORD_FORMULAS = {
    "maior": [0, 4, 7],
    "menor": [0, 3, 7],
    "diminuto": [0, 3, 6],
    "aumentado": [0, 4, 8],
    "maior com sétima maior": [0, 4, 7, 11],
    "dominante (7)": [0, 4, 7, 10],
    "menor com sétima": [0, 3, 7, 10],
    "meio-diminuto": [0, 3, 6, 10],
    "diminuto com sétima": [0, 3, 6, 9],
    "sus2": [0, 2, 7],
    "sus4": [0, 5, 7],
    "maior com nona": [0, 4, 7, 11, 14],
    "dominante com nona": [0, 4, 7, 10, 14],
    "menor com nona": [0, 3, 7, 10, 14],
}


# --- Instrumentos (afinações) ---

TUNINGS = {
    "viola_caipira_rio_abaixo": ["G", "D", "G", "B", "D"],
    "viola_caipira_cebolao_D":  ["A", "D", "F#", "A", "D"],
    "viola_caipira_cebolao_E":  ["E", "B", "G#", "E", "B"],
}

MAX_FRET = 14


def chord_frets(tuning: list[str], chord_notes: list[str]) -> list[int]:
    chord_values = {note_value(n) for n in chord_notes}
    frets = []
    for open_note in tuning:
        open_val = note_value(open_note)
        best = None
        for fret in range(MAX_FRET + 1):
            if (open_val + fret) % 12 in chord_values:
                best = fret
                break
        frets.append(best)
    return frets


def format_frets(frets: list[int]) -> str:
    return "-".join("X" if f is None else str(f) for f in frets)


def fretboard_diagram(tuning_name: str, tuning: list[str], scale_notes: list[str], root: str) -> str:
    scale_values = {note_value(n) for n in scale_notes}
    root_value = note_value(root)
    chromatic = _chromatic_for(root)

    label_width = max(len(f"{t} ({i+1}ª)") for i, t in enumerate(tuning))
    col_width = 4

    header = " " * label_width + " ||"
    for f in range(MAX_FRET + 1):
        header += f"{f:>{col_width}}"
    lines = [f"  {tuning_name} — escala de {root}", "", header]

    for i, open_note in enumerate(tuning):
        open_val = note_value(open_note)
        label = f"{open_note} ({i+1}ª)"
        row = f"{label:>{label_width}} ||"
        for fret in range(MAX_FRET + 1):
            val = (open_val + fret) % 12
            if val in scale_values:
                name = chromatic[val]
                if val == root_value:
                    name = f"[{name}]"
                row += f"{name:>{col_width}}"
            else:
                row += f"{'·':>{col_width}}"
        lines.append(row)

    return "\n".join(lines)


def _chromatic_for(root: str) -> list[str]:
    if root in FLAT_KEYS or "b" in root:
        return CHROMATIC_FLATS
    return CHROMATIC_SHARPS


def note_name(value: int, root: str = "C") -> str:
    return _chromatic_for(root)[value % 12]


def note_value(name: str) -> int:
    return NOTE_TO_VALUE[name]


def build_scale(root: str, formula_name: str) -> list[str]:
    formula = SCALE_FORMULAS[formula_name]
    value = note_value(root)
    chromatic = _chromatic_for(root)
    notes = [chromatic[value % 12]]
    for step in formula:
        value += step
        notes.append(chromatic[value % 12])
    return notes


def build_chord(root: str, formula_name: str) -> list[str]:
    formula = CHORD_FORMULAS[formula_name]
    base = note_value(root)
    chromatic = _chromatic_for(root)
    return [chromatic[(base + interval) % 12] for interval in formula]


def interval_between(note1: str, note2: str) -> int:
    return (note_value(note2) - note_value(note1)) % 12


def interval_name(semitones: int) -> str:
    semitones = semitones % 12
    for name, value in INTERVALS.items():
        if value == semitones:
            return name
    return f"{semitones} semitons"


def describe_intervals(notes: list[str]) -> list[str]:
    result = []
    for i in range(len(notes) - 1):
        st = interval_between(notes[i], notes[i + 1])
        result.append(f"{notes[i]} -> {notes[i+1]}: {st} semitom(s) ({interval_name(st)})")
    return result


# --- Interface interativa ---

def print_section(title: str, items: list[str]):
    print(f"\n  {title}")
    print("  " + "-" * len(title))
    for item in items:
        print(f"    {item}")


def show_scale(root: str, name: str):
    notes = build_scale(root, name)
    print_section(f"Escala {name} de {root}", [" - ".join(notes)])
    print_section("Intervalos", describe_intervals(notes))
    if TUNINGS:
        for tuning_name, strings in TUNINGS.items():
            print()
            print(fretboard_diagram(tuning_name, strings, notes, root))


def show_chord(root: str, name: str):
    notes = build_chord(root, name)
    print_section(f"Acorde {root} {name}", [" - ".join(notes)])
    print_section("Intervalos a partir da tônica", [
        f"{root} -> {n}: {interval_between(root, n)} semitom(s) ({interval_name(interval_between(root, n))})"
        for n in notes[1:]
    ])
    if TUNINGS:
        lines = []
        for tuning_name, strings in TUNINGS.items():
            frets = chord_frets(strings, notes)
            lines.append(f"{tuning_name} ({'-'.join(strings)}): {format_frets(frets)}")
        print_section("Instrumentos", lines)


def menu():
    print("\n=== Acordes & Escalas ===")
    print("  1. Montar escala")
    print("  2. Montar acorde")
    print("  3. Calcular intervalo entre duas notas")
    print("  0. Sair")
    return input("\nEscolha: ").strip()


def choose_from(options: dict, label: str) -> str:
    names = list(options.keys())
    print(f"\n  {label}:")
    for i, name in enumerate(names, 1):
        print(f"    {i}. {name}")
    while True:
        choice = input("  Número: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(names):
            return names[int(choice) - 1]
        print("  Opção inválida.")


def ask_note(prompt: str = "  Nota (ex: C, D#, Bb): ") -> str:
    while True:
        n = input(prompt).strip()
        if n in NOTE_TO_VALUE:
            return n
        print("  Nota inválida. Use: " + ", ".join(CHROMATIC_SHARPS + ["Db", "Eb", "Gb", "Ab", "Bb"]))


def main():
    while True:
        choice = menu()
        if choice == "1":
            root = ask_note()
            formula = choose_from(SCALE_FORMULAS, "Escalas disponíveis")
            show_scale(root, formula)
        elif choice == "2":
            root = ask_note()
            formula = choose_from(CHORD_FORMULAS, "Acordes disponíveis")
            show_chord(root, formula)
        elif choice == "3":
            print("\n  Primeira nota:")
            n1 = ask_note()
            print("  Segunda nota:")
            n2 = ask_note()
            st = interval_between(n1, n2)
            print(f"\n    {n1} -> {n2}: {st} semitom(s) ({interval_name(st)})")
        elif choice == "0":
            break
        else:
            print("  Opção inválida.")


if __name__ == "__main__":
    main()
