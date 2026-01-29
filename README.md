# Analýza mezd a cen potravin v ČR

Tento projekt analyzuje data o mzdách a cenách potravin v České republice (období 2006–2018) a zkoumá jejich vztah k HDP.

## Výsledky výzkumných otázek

### 1. Rostou mzdy ve všech odvětvích nepřetržitě?
Ne, mzdy nerostou ve všech odvětvích nepřetržitě.
- Z dat vyplývá, že v některých odvětvích došlo v určitých letech k meziročnímu poklesu.
- Tento trend byl patrný zejména v období hospodářské krize a těsně po ní (kolem roku 2009–2013), kdy klesaly mzdy například v odvětví těžby a dobývání nebo ubytování.

### 2. Kolik mléka a chleba si můžeme koupit (2006 vs 2018)?
Dostupnost obou potravin se zvýšila.
- **Chléb:** V roce 2006 bylo možné za průměrnou mzdu koupit **1262** kg chleba, v roce 2018 to bylo **1319** kg.
- **Mléko:** V roce 2006 bylo možné koupit **1409** litrů mléka, v roce 2018 to bylo **1614** litrů.

### 3. Která potravina zdražuje nejpomaleji?
- Nejpomaleji zdražovala kategorie **Cukr krystal**.
- Její cena se za sledované období změnila o **-27.52%**.

### 4. Kdy potraviny zdražily výrazně víc než mzdy?
- Ano, existuje rok, kdy byl nárůst cen potravin výrazně vyšší než růst mezd (rozdíl > 10 %).
- Byl to rok **2013** (doplň rok, pravděpodobně 2013), kdy ceny potravin vzrostly výrazněji, zatímco mzdy stagnovaly nebo rostly pomaleji.

### 5. Má HDP vliv na mzdy a ceny?
- Z analýzy je patrná korelace mezi vývojem HDP a mzdami.
- V letech, kdy HDP výrazně rostlo (např. 2015–2017), následně rostly i mzdy.
- Naopak v roce 2009, kdy HDP kleslo (-4,66 %), došlo v následujících letech ke stagnaci růstu mezd.

---

## O datech a metodice
- Data pocházejí z veřejné databáze Engeto.
- Pro analýzu byla použita data z let 2006 až 2018, která jsou společná pro mzdy i ceny potravin.
- Data o HDP a dalších ekonomických ukazatelích byla čerpána z tabulky `economies` a propojena s daty z ČR.
- Případné chybějící hodnoty (NULL) byly v rámci SQL dotazů odfiltrovány, aby nezkreslily průměry.
