# System Detekcji Pijawek (Leech System)

Niniejszy dokument opisuje wdrożony w aplikacji Con Calma mechanizm automatycznej detekcji "pijawek" (ang. Leech) – fiszek, z których przyswojeniem użytkownik ma przewlekłe problemy, powodując tzw. "pętlę frustracji".

## 1. Zmiany w Modelu SwiftData (`Flashcard`)
Aby uodpornić system na powtarzające się błędy, wdrożono cztery nowe parametry, które skutecznie wyparły stary, mniej optymalny licznik `consecutiveMistakes`:

*   `lapsesCount: Int` – licznik błędów "pod rząd".
*   `totalReviews: Int` – całkowita liczba podejść (powtórek) danej fiszki.
*   `successReviews: Int` – całkowita liczba ocenionych pozytywnie (.good) powtórek.
*   `isLeech: Bool` – flaga bezpieczeństwa zawieszająca wpadnięcie fiszki w cykl powtórek.

## 2. Działanie Logiki (SRSAlgorithm)
Zaimplementowano hybrydowe, adaptacyjne progi wykrywania pijawek, opierające się zarówno na statystyce krótkoterminowej, jak i długoterminowej.

### Nagradzanie za sukces (.good):
Gdy użytkownik przypomni sobie słówko prawidłowo, algorytm natychmiastowo wyzerowuje `lapsesCount`. Pomaga to uniknąć błędnego oznaczania trudnych słówek jako pijawek w cyklu życia aplikacji, skupiając się tylko na bieżącej "pętli".

### Dwa filary detekcji (Zawieszenie):
Karta automatycznie zmienia swój status na `isLeech = true` w dwóch przypadkach:
1.  **Sztywny Próg Serii Porażek (Lapses Threshold):** Użytkownik ocenia fiszkę negatywnie 5 razy pod rząd (`lapsesCount >= 5`). Wyłapuje to nowe słówka stawiające nadmierny opór.
2.  **Płynny Próg Stabilności (Ease Ratio):** Karta była oceniana przynajmniej 10 razy, a skuteczność sukcesu jest rażąco niska (`Ease Ratio < 30%`). Przeciwdziała zjawisku słówek, które regularnie uciekają z pamięci na wyższych interwałach.

## 3. Integracja z Widokami Interfejsu (Views)

*   **Pominięcie z Algorytmu:** Fiszki zawieszone ("Leech") nie wchodzą w skład `dueCards` (`DashboardView`) ani domyślnych pakietów w wolnym treningu (`FreePracticeConfigView`), skutecznie zwalczając frustrację w codziennych sesjach.
*   **Oznaczenie Wizualne:** Zlokalizowane w głównym widoku biblioteki (`LibraryView`), podejrzane fiszki są obrandowane wyraźną, czerwoną etykietą "Leech", zachęcając użytkownika do manualnej interwencji.
*   **Undo/Cofanie:** Rejestrowane parametry pijawki są w pełni wspierane przez logikę `FlashcardBackup` w trwających sesjach powtórkowych, więc przycisk "Cofnij" zrewiduje również i ewentualne zawieszenie.

## 4. Reanimacja Pijawki (Soft Reset)
Jeśli użytkownik uzna, że jest gotowy sprostać wyzwaniu, ulepszy zdanie kontekstowe bądź uzupełni mnemotechniki, może wymusić twardy reset statusu. Przycisk w `EditFlashcardView` uruchamia ukrytą pod maską metodę `reviveLeech()`, która:
1. Odznacza flagę blokującą.
2. Resetuje zgromadzone statystyki (lapses, total, success).
3. Podbija drastycznie ścięty mnożnik trudności do standardowej i bezpiecznej puli `easeFactor = 2.0`.
4. Ustawia interwał powtórkowy na pierwszy dzień.

System w swoim działaniu jest precyzyjny, skalowalny i rygorystycznie testowany.
