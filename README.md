# Con Calma

Con Calma to minimalistyczna, elegancka i skuteczna aplikacja do nauki języka włoskiego na system iOS, zbudowana z wykorzystaniem najnowszych technologii Apple: **Swift**, **SwiftUI** oraz **SwiftData**.

## Funkcjonalności

- **Tryby nauki:**
  - **Tryb fiszek:** Klasyczne odwracanie kart z ukrytą odpowiedzią z możliwością szybkiego gestu swipe w lewo lub w prawo.
  - **Tryb wpisywania:** Testowanie poprawnej pisowni ze sprawdzaniem poprawności w czasie rzeczywistym.
  - **Trening:** Swobodna praktyka poza głównym systemem powtórek.
- **System powtórek przestrzennych (SRS):** Oparty na zoptymalizowanym algorytmie, który decyduje, kiedy powinna nastąpić następna powtórka słowa dla optymalnego zapamiętania.
- **Wymowa TTS (Text-To-Speech):** Zintegrowana natywna synteza mowy w języku włoskim wspierająca proces poprawnej wymowy i przyswajania.
- **Śledzenie postępów:** Panel główny "Dashboard" z podsumowaniem czasu nauki, poznanych słów oraz codziennej serii (streak).
- **Zarządzanie biblioteką:** Szybka możliwość edytowania fiszek w każdym momencie nauki, dodawania nowych słówek i zarządzania kolekcją.

## Technologie

- **SwiftUI:** Nowoczesny, deklaratywny interfejs użytkownika, który wygląda naturalnie i działa płynnie.
- **SwiftData:** Trwałe i niezawodne przechowywanie danych w pełni połączone z frameworkiem SwiftUI.
- **AVFoundation:** Wykorzystanie `AVSpeechSynthesizer` dla realistycznego czytania słówek w języku włoskim.

## Jak to działa?

Zawsze, gdy spotykasz nowe włoskie słówko, jest ono wprowadzane do bazy. W wyznaczonym czasie (liczony przez współczynnik łatwości - *Ease Factor*) aplikacja przypomni o danym słowie. Jeśli odpowiesz poprawnie - czas się wydłuża, jeśli błędnie - aplikacja upewni się, by powtórzyć to słowo szybciej.

Więcej na ten temat można sprawdzić w kodzie, głównie pliki modeli w `Con Calma/Models/` oraz serce aplikacji w `Con Calma/Views/`.

Con Calma - zaufaj procesowi, ucz się bez stresu.
