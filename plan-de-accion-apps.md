# Plan de Acción — MiBebé


---

## PARTE 1 — MiBebé (prioridad principal)

### Fase 0 · Esta semana — Higiene y cimientos

1. ~~**Eliminar el placeholder de la pestaña Sleep** ("Use this screen as the base for the baby's upcoming rest features"). Sustituir por un "Próximamente 🌙" cuidado u ocultar la pestaña. Nadie debe ver texto de desarrollo justo antes de que le pidas dinero.~~ **Hecho**
2. ~~**Implementar el prompt nativo de reseñas** (SKStoreReviewController), disparado tras un momento de valor: p. ej., tras registrar la toma nº 10, o al ver la curva de peso con datos de varias semanas. Las reseñas son el combustible que sostiene posiciones ASO.~~ **Hecho**
3. ~~**Instrumentar analítica básica de embudo** (si no la tienes): apertura → registro de primer evento → retorno día 1/7/30. Sin esto, las decisiones de paywall serán a ciegas.~~ **Hecho**
4. **Activar la página de producto en todos los idiomas que ya soporte la UI** (la app está en inglés en las capturas — asegúrate de que la localización EN de la ficha existe y está cuidada).

### Fase 1 · Semanas 1-2 — Iteración ASO #2 (quirúrgica)

**Objetivo:** empujar 2-3 keywords de volumen medio al top 10 sin perder el #8 de "mi bebe".

**España (ES):**
- ~~**Título (30 car.):** mantener "mi bebé" al principio (es tu motor; cuanto antes en el título, más peso). Incorporar "lactancia" si no está ya al inicio. Ejemplo de estructura: `MiBebé: Lactancia y Tomas` (25 car.).~~ **Hecho**
- **Subtítulo (30 car.):** apuntar a percentiles y peso, tu diferenciador real. Ejemplo: `Peso, percentiles y pañales` (27 car.). **Pendiente — discutir con Claude**
- **Campo keywords (100 car.):** eliminar las pop-5 que ocupan sitio (hitos, curva, recien, vanidad de posiciones sin volumen) y poblar con: `materna,biberon,extraccion,amamantar,sueño,recien,nacido,toma,registro,crecimiento,percentil` — ajustando para no repetir nada que ya esté en título/subtítulo (Apple las indexa igual y repetir desperdicia caracteres). Sin espacios tras las comas, sin plurales si está el singular. **Pendiente — discutir con Claude**

**Reglas duras del campo keywords:** sin espacios, sin repetir términos del título/subtítulo, sin "app", sin plurales redundantes, cada carácter cuenta.

**Inglés (EN-GB/EN-US) — reescritura completa con lógica long-tail:** **Pendiente — discutir con Claude**
- Olvidar "baby tracker" como apuesta de título (dificultad 64). Ir a términos de dificultad <25: `newborn tracker`, `breastfeeding log`, `baby weight percentile`, `nappy log` (UK), `feeding log`.
- Ejemplo título EN: `Newborn Tracker: Baby Weight` / Subtítulo: `Breastfeeding & nappy log`.
- Bonus: la localización EN-GB también indexa en España y gran parte de Latam → estas keywords suman doble.

**Medición:** revisar Astro semanalmente. Criterio de éxito a 3-4 semanas: "lactancia materna" y "percentil" en top 15, "mi bebe" estable o mejor, baseline de impresiones >60/día.

### Fase 2 · Semanas 2-6 — Construir la monetización

**Principio rector:** registrar es gratis para siempre; *entender* lo registrado es premium. El muro nunca toca la acción diaria.

**Tramo GRATIS:**
- Registro completo: tomas (cronómetro + lado), biberón, pañales, peso.
- Vista "hoy" / resumen diario.
- 1 bebé, 1 cuidador, historial de 7 días.
- Gráfica de peso simple (sin referencia WHO).
- Tip of the day.

**Tramo PREMIUM (mucho ya está construido):**
- Predicción de próxima toma ("Next feed in 2h 6min").
- Feeding track vs. patrón ("Below usual / usually still takes X ml").
- Distribución de tomas (% pecho izq/der vs. biberón).
- Curvas WHO + percentiles en peso (la gráfica simple queda gratis; la capa WHO es premium).
- Historial completo (más allá de 7 días).

**Premium a construir (en este orden de impacto):**
1. **Sincronización multi-cuidador** (pareja/abuelos registran el mismo bebé en tiempo real) — gancho nº 1 de la categoría.
2. **Exportar PDF para el pediatra** (con curvas WHO incluidas — barato de construir, convierte muy bien).
3. **Copia de seguridad en la nube** ("no pierdas los primeros meses de Gonzalo" — aversión a la pérdida).
4. Más adelante: múltiples bebés (gemelos/hermanos), recordatorios inteligentes, widget/Apple Watch.

**Precios (ciclo de vida del usuario ~12-18 meses):**
- Mensual: 4-5 €.
- **Anual: 25-30 € con trial de 7 días** (el plan que hay que empujar).
- Lifetime: 40-50 € (funciona muy bien en bebés: el padre sabe que la etapa es finita).
- Nada de plan semanal en esta app.

**Colocación del paywall:**
- Paywall *suave* al final del onboarding (mostrable, saltable).
- Paywalls *contextuales* en los momentos de deseo: al tocar una función premium (predicción, WHO, exportar), al llegar al límite de 7 días de historial, al intentar invitar a la pareja. Estos convierten mejor que el de onboarding en esta categoría.
ti
**Expectativa honesta:** con el volumen actual, los ingresos serán simbólicos. El objetivo de esta fase es **aprender el embudo** (instalación→trial→pago) y construir el LTV que luego justificará invertir en tráfico.

### Fase 3 · Meses 2-3 — Expansión

1. **Localización masiva de la ficha** (y de la UI si es viable): EN ya hecho en Fase 1; añadir **PT-BR** (mercado enorme y menos competido), **FR, DE, IT**. Cada idioma = nuevo set de título+subtítulo+keywords para rankear.
2. **Completar la función de Sueño** (registro gratis, análisis de patrones premium). Es de las búsquedas más demandadas del nicho.
3. **Motor de reseñas a régimen:** objetivo 20-30 valoraciones en España. Pesan en ranking y en conversión.
4. **Segunda iteración ASO** con datos de la primera: doblar en lo que subió, podar lo que no.

### Fase 4 · Meses 3-6 — Tracción externa y decisión de pipeline

1. **Tráfico externo:** grupos de Facebook de lactancia/maternidad, subreddits, contenido corto (TikTok/IG) sobre percentiles y sueño del bebé. El ASO solo no romperá el techo del nicho en español.
2. **Si el funnel de pago ya da un LTV medible:** test pequeño de Apple Search Ads sobre tus keywords ganadoras ("mi bebe", "lactancia materna") — solo si LTV > coste por instalación con margen.
3. **Decisión de pipeline:** si la monetización está viva y estable, arrancar la **app de embarazo** (reutiliza ~60% del trabajo; el embudo embarazo→bebé alimenta esta app gratis a perpetuidad). No empezar antes: una app monetizando bien vale más que dos a medias.

### KPIs de MiBebé

| Métrica | Hoy | 1 mes | 3 meses | 6 meses |
|---|---|---|---|---|
| Impresiones/día | ~35 | 60-80 | 120-200 | 250+ |
| Descargas/mes | ~20 | 40-60 | 100-180 | 250+ |
| Conversión ficha | 5.3% | ≥5% | ≥5% | ≥5% |
| Reseñas (ES) | ~0 | 10 | 30 | 60 |
| Suscripción | — | Live | Trial→pago ≥30% | LTV medido |

---

## Principios que gobiernan todo el plan

1. **El ASO es tu palanca probada** — ya duplicaste impresiones una vez con metadatos. Itera quirúrgicamente, no a lo ancho.
2. **Posición sin volumen no es visibilidad.** Top 10 en keywords pop-5 vale cero. Persigue pop 8-50 con dificultad <25.
3. **Registrar gratis, entender de pago.** El muro de la app del bebé nunca toca la acción diaria.
4. **Monetiza pronto con mano suave:** el objetivo a corto plazo es aprender el embudo, no exprimir ingresos.
5. **Las reseñas sostienen lo que el ASO conquista.** Sin ellas, los rankings se desinflan (lo estás viendo en el espejo).
