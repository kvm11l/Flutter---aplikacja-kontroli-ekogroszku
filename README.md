Aplikacja do śledzenia spalania oraz raportowania zużycia ekogroszku

Funkcjonalności aplikacji

Aplikacja to narzędzie do zarządzania zakupami i zużyciem ekogroszku. Oferująca następujące funkcje:

1. Zarządzanie zakupami
Rejestracja nowych zakupów ekogroszku (dostawca, ilość, cena, data), 
Przegląd historii zakupów z możliwością sortowania,
Szczegółowe informacje o każdym zakupie. 

2. Śledzenie zapasów
Monitorowanie stanu magazynu, 
Wizualizacja pozostałych zapasów (procentowo i wagowo), 
Automatyczne aktualizowanie stanu po rejestracji zużycia.

3. Rejestracja zużycia
Zapisywanie okresów spalania ekogroszku, 
Śledzenie dziennego zużycia, 
Rejestrowanie warunków pogodowych i temperatury, 
Określanie przeznaczenia ciepła (np. woda użytkowa, grzejniki). 

4. Raporty i statystyki
Generowanie podsumowań miesięcznych, 
Wykresy zużycia dziennego, 
Analiza rozkładu przeznaczenia ciepła, 
Średnie dzienne zużycie.

5. Integracja z pogodą (dla miasta Częstochowa)
Wyświetlanie aktualnej temperatury i warunków pogodowych, 
Prognoza na najbliższe dni, 
Powiązanie zużycia z warunkami atmosferycznymi.

6. Dodatkowe funkcje
System notatek do zakupów,  
Możliwość edycji i usuwania wpisów,  
Responsywny interfejs dostosowany do urządzeń mobilnych.


Aplikacja została zbudowana w oparciu o wzorzec MVC (Model-View-Controller) z wyraźnym podziałem na:
Modele (coal_purchase.dart, coal_usage.dart) - reprezentują dane
Widoki (ekrany w folderze screens) - interfejs użytkownika
Kontrolery (logika w stanach widgetów) - zarządzają przepływem danych

Baza danych SQLite jest używana do trwałego przechowywania wszystkich informacji, z warstwą dostępu do danych w DatabaseHelper.

Wykorzystane technologie:
Flutter - główny framework do budowy aplikacji mobilnych na platformy iOS i Android
Dart - język programowania używany w Flutterze
sqflite - plugin do obsługi bazy danych SQLite na urządzeniach mobilnych
HTTP Client - do pobierania danych pogodowych z zewnętrznego API
syncfusion_flutter_charts - biblioteka do tworzenia wykresów i wizualizacji danych
intl - do formatowania dat, walut i innych danych lokalizacyjnych
Material Design - system designu Google zastosowany w interfejsie użytkownika
