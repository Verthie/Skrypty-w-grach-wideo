#!/usr/bin/env python3
import sys
import re

try:
    import requests
except ImportError:
    print("brak requests: pip install requests")
    sys.exit(1)

OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL_NAME = "llama3"

MENU = """
- Żurek staropolski – 18 zł
- Zupa pomidorowa – 14 zł
- Schabowy z ziemniakami – 38 zł
- Pierogi ruskie – 32 zł
- Kurczak w sosie śmietanowym – 42 zł
- Woda mineralna – 8 zł
- Kawa – 10 zł
- Szarlotka z lodami – 22 zł
"""

# trenowanie przez prompt
SYSTEM_PROMPT = f"""Jesteś kelnerem w restauracji "Złoty Smok". Odpowiadaj TYLKO po polsku, zwięźle (2-3 zdania).

Obsługujesz trzy rodzaje intencji gościa:
1. POWITANIE – gdy gość się wita lub zaczyna rozmowę, przywitaj go serdecznie i zapytaj czego potrzebuje.
2. MENU – gdy gość pyta o kartę, dania lub ceny, przedstaw mu nasze menu.
3. ZAMÓWIENIE – gdy gość zamawia konkretne danie, potwierdź zamówienie i zapytaj czy coś jeszcze.

Nasze menu:
{MENU}

Jeśli gość pyta o coś innego niż restauracja, grzecznie odmów i wróć do tematu."""

INTENTS = {
    "powitanie": [r"\b(cześć|hej|witaj|dzień dobry|dobry wieczór|siema|hello)\b"],
    "menu":      [r"\b(menu|karta|dania|co macie|co polecacie|jadłospis|cena|ile kosztuje)\b"],
    "zamówienie":[r"\b(poproszę|zamawiam|wezmę|chcę|chciałbym|chciałam|daj mi)\b"],
}

def wykryj_intencje(tekst: str) -> str:
    for nazwa, wzorce in INTENTS.items():
        for wzorzec in wzorce:
            if re.search(wzorzec, tekst, re.IGNORECASE):
                return nazwa
    return "inne"

def zapytaj_model(historia: list) -> str:
    payload = {
        "model": MODEL_NAME,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT}] + historia,
        "stream": False,
    }
    try:
        r = requests.post(OLLAMA_URL, json=payload, timeout=60)
        return r.json()["message"]["content"].strip()
    except requests.exceptions.ConnectionError:
        return "[BŁĄD] Ollama nie działa. Uruchom: ollama serve"
    except Exception as e:
        return f"[BŁĄD] {e}"

def main():
    print("Restauracja Złoty Smok – Czatbot")
    print("(wpisz 'koniec' aby zakończyć)")
    print()

    historia = []

    while True:
        try:
            wejscie = input("Ty: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nDo widzenia!")
            break

        if not wejscie:
            continue
        if wejscie.lower() in ("koniec", "exit", "quit"):
            print("Do widzenia!")
            break

        intencja = wykryj_intencje(wejscie)
        print(f"[intencja: {intencja}]")

        historia.append({"role": "user", "content": wejscie})
        odpowiedz = zapytaj_model(historia)
        historia.append({"role": "assistant", "content": odpowiedz})

        print(f"Kelner: {odpowiedz}")
        print()

if __name__ == "__main__":
    main()
