# Kreator (creathor)

App Flutter para creadores de contenido que centraliza finanzas de colaboraciones,
registro de campañas con split automático, comparador de supermercado y calendario
de entregas. Todos los datos se guardan en una base de datos **SQLite local**
(`sqflite`), sin backend.

El diseño procede del proyecto de Stitch
[Kreator](https://stitch.withgoogle.com/projects/1196971195480652812): paleta Material 3
tonal (superficie crema `#FBF9F6`, primario negro, acento menta `#26E19A`, violeta
`#9466FF`), tipografías **Space Grotesk** (titulares y cifras) y **Plus Jakarta Sans**
(cuerpo), cápsulas negras para los filtros y tarjetas blancas con sombra suave.

## Pantallas

| Pestaña | Archivo | Qué hace |
|---|---|---|
| Finanzas | `lib/screens/finance/dashboard_screen.dart` | Hero con el neto del mes, barra segmentada neto/Hacienda/agencia/gastos, hucha fiscal, pipeline de campañas por estado (pendientes de cobro, en producción, cobradas) con alerta de vencimiento, otros ingresos netos (trabajos fuera de campañas, sin IVA ni IRPF), gastos deducibles con IVA recuperable al 21%, botón de ocultar importes. |
| Detalle de campaña | `lib/screens/finance/campaign_detail_screen.dart` | Desglose financiero, cambio de estado (producción → facturada → cobrada), checklist de entregables (toca para avanzar el estado, desliza para borrar), hoja de ruta con hitos, contacto y nota de negociación. |
| Campaña | `lib/screens/campaign/new_campaign_screen.dart` | Formulario con chips de entregables, calculadora en tiempo real con sliders de agencia e IRPF, términos de pago (30/60 días, 50% anticipo), fecha de draft y publicación que generan deadlines automáticamente. |
| Súper | `lib/screens/grocery/grocery_screen.dart` | Cesta con añadido rápido, selector de supermercado activo, ahorro acumulado frente al más caro, diferencial por producto, gráfica de barras comparando la cesta en cada cadena y editor de precios por supermercado. |
| Deadlines | `lib/screens/deadlines/deadlines_screen.dart` | Tira semanal/mensual con puntos por tipo, filtros Rodaje / Draft / Publicación, timeline con checklist de tareas, alerta de borradores pendientes de validación y formulario de nuevo compromiso. |

## Arquitectura

```
lib/
├── main.dart                  # init de intl, SQLite y providers
├── core/
│   ├── db/app_database.dart   # esquema SQLite (sqflite / sqflite_common_ffi)
│   ├── theme/                 # AppColors, AppText, buildAppTheme()
│   └── utils/formatters.dart  # euros, fechas y etiquetas en español
├── models/                    # Campaign, Deliverable, Expense, Product, CartItem, Deadline…
├── repositories/              # acceso a tablas (CRUD + joins)
├── providers/                 # ChangeNotifier con la lógica de negocio
├── screens/                   # una carpeta por pestaña + shell con bottom nav
└── widgets/common.dart        # AppHeader, SurfaceCard, PillChip, Tag, SegmentedBar…
```

Tablas: `campaigns`, `deliverables`, `expenses`, `incomes`, `supermarkets`,
`products`, `product_prices`, `cart_items`, `deadlines`, `deadline_tasks`, `settings`.
Las claves foráneas están activas (`PRAGMA foreign_keys = ON`) con borrado en cascada.

La app arranca vacía. Solo se registran las cadenas Mercadona, Carrefour, Lidl y Dia
para el comparador; se pueden añadir más desde la pestaña Súper.

El IVA es del 21% (`lib/core/constants.dart`). Las campañas descuentan IVA y agencia
del fee bruto. Los ingresos de otros trabajos se guardan ya en neto y se suman
íntegros al dinero del mes.

**Migraciones.** La versión 2 del esquema añade la tabla `incomes` y borra los datos
de ejemplo que la versión 1 insertaba al crear la base. Esa migración vacía campañas,
gastos, productos, cesta y deadlines de instalaciones previas.

## Ejecutar

```bash
flutter pub get
flutter run            # Android / iOS
flutter run -d windows # requiere Visual Studio con "Desktop development with C++"
```

En Windows y Linux la base de datos usa `sqflite_common_ffi`; en móvil usa el plugin
nativo de `sqflite`. Las fuentes se descargan con `google_fonts` la primera vez
(con fallback del sistema si no hay red).

## Tests

```bash
flutter analyze
flutter test
```

`test/database_test.dart` cubre el esquema y los providers sobre una base de datos
en memoria (split de campaña, creación con deadlines, agregados del mes, comparador
de cesta, filtros de calendario, otros ingresos). `test/migration_test.dart` comprueba
la migración v1 → v2. `test/widget_test.dart` monta la app completa y navega por las
cuatro pestañas, los otros ingresos y el detalle de campaña.
