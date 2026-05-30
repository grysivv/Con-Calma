# Con Calma

Con Calma to minimalistyczna, elegancka i skuteczna aplikacja do nauki języka włoskiego na system iOS, zbudowana z wykorzystaniem najnowszych technologii Apple: **Swift**, **SwiftUI** oraz **SwiftData**.

## Funkcjonalności

- **Tryby nauki:**
  - **Tryb fiszek:** Klasyczne odwracanie kart z ukrytą odpowiedzią z możliwością szybkiego gestu swipe w lewo (nie potrafię) lub w prawo (umiem). Najnowsza wersja aplikacji pozwala wykonywać gest od razu (nawet na nieodwróconej polskiej stronie)!
  - **Tryb wpisywania:** Testowanie poprawnej pisowni. Pozwala na wygodne pominięcie w razie błędu i od razu odsłania poprawną odpowiedź dla płynnej i błyskawicznej nauki. Z poziomu trybu wpisywania można teraz również natychmiast edytować zawartość karty!
  - **Trening:** Swobodna praktyka poza głównym systemem powtórek (SRS).
- **System powtórek przestrzennych (SRS):** Oparty na zoptymalizowanym algorytmie, który decyduje, kiedy powinna nastąpić następna powtórka słowa dla optymalnego zapamiętania.
- **Wymowa TTS (Text-To-Speech):** Zintegrowana natywna synteza mowy w języku włoskim wspierająca proces poprawnej wymowy i przyswajania.
- **Śledzenie postępów:** Panel główny "Dashboard" z podsumowaniem czasu nauki, poznanych słów oraz codziennej serii (streak). Dashboard został też optymalnie dopasowany do ekranu (zablokowany scroll).
- **Zarządzanie biblioteką:** Szybka możliwość edytowania fiszek w każdym momencie nauki, dodawania nowych słówek i zarządzania kolekcją. Nowa biblioteka wspiera gesty usunięcia (w prawo) oraz edycji (w lewo).
- **Szybkie usuwanie (Grupowe):** Wykorzystując natywny mechanizm zaznaczania wielokrotnego, użytkownicy mają możliwość łatwego wybrania wielu słówek naraz z biblioteki do bezpośredniego, grupowego skasowania.

## Technologie i Optymalizacje

- **SwiftUI:** Nowoczesny, deklaratywny interfejs użytkownika, który wygląda naturalnie i działa płynnie. Zoptymalizowano użycie `ScrollView` oraz przepływ układu graficznego.
- **SwiftData:** Trwałe i niezawodne przechowywanie danych w pełni połączone z frameworkiem SwiftUI z wieloma mądrymi limitami na pobieranie danych.
- **Wydajność:** W aplikacji zastosowano szereg ulepszeń optymalizacyjnych oznaczonych jako `// performance hack:`, co minimalizuje alokację pamięci i redukuje zużycie przy ogromnej liczbie list (np. użycie NSCache czy zoptymalizowanych algorytmów sortowania tablic dla Dashboardu).
- **AVFoundation:** Wykorzystanie `AVSpeechSynthesizer` dla realistycznego czytania słówek w języku włoskim.

## Jak to działa?

Zawsze, gdy spotykasz nowe włoskie słówko, jest ono wprowadzane do bazy. W wyznaczonym czasie (liczony przez współczynnik łatwości - *Ease Factor*) aplikacja przypomni o danym słowie. Jeśli odpowiesz poprawnie - czas się wydłuża, jeśli błędnie - aplikacja upewni się, by powtórzyć to słowo szybciej.

Więcej na ten temat można sprawdzić w kodzie, głównie pliki modeli w `Con Calma/Models/` oraz serce aplikacji w `Con Calma/Views/`.

Con Calma - zaufaj procesowi, ucz się bez stresu.
