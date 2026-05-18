# Kanban Board — Minimarket App

> Estado actualizado: 2026-05-18
> Leyenda: 🔴 Bloqueado | 🟡 En Progreso | 🟢 Completado | ⚪ Pendiente

---

## ⚪ BACKLOG

| ID | Tarea | Prioridad | Dependencia |
|----|-------|-----------|-------------|
| F2-01 | Integrar Google Maps Flutter | Media | MVP completo |
| F2-02 | Pantalla de ubicación de tienda con ruta | Media | F2-01 |
| F2-03 | Agregar imágenes de productos | Baja | MVP completo |
| F2-04 | Autenticación Firebase | Baja | MVP completo |
| F2-05 | Historial de pedidos | Baja | F2-04 |

---

## ⚪ POR HACER (Sprint MVP)

| ID | Tarea | Prioridad | Dependencia |
|----|-------|-----------|-------------|
| — | Sprint MVP completado ✅ | — | — |

---

## 🟡 EN PROGRESO

| ID | Tarea | Asignado | Notas |
|----|-------|----------|-------|
| — | No hay tareas en progreso | — | — |

---

## 🟢 COMPLETADO

| ID | Tarea | Fecha |
|----|-------|-------|
| SETUP-01 | Crear proyecto Flutter en `E:\flutter-minimarket` | 2026-05-18 |
| SETUP-02 | Configurar `minSdk = 24` en Android | 2026-05-18 |
| SETUP-03 | Configurar Firebase (google-services.json + Gradle) | 2026-05-18 |
| SETUP-04 | Instalar dependencias `firebase_core` + `cloud_firestore` | 2026-05-18 |
| DOC-01 | Crear `datasheet.md` con 85 productos iniciales | 2026-05-18 |
| DOC-02 | Crear `example.md` con guía de referencia | 2026-05-18 |
| DOC-03 | Crear `sdd-master.md` con arquitectura completa | 2026-05-18 |
| DOC-04 | Crear `kanban.md` (este documento) | 2026-05-18 |
| MVP-01 | Crear `config/theme.dart` con paleta amarillo/azul oscuro | 2026-05-18 |
| MVP-02 | Crear modelo `Producto` con stock + disponible | 2026-05-18 |
| MVP-03 | Crear `FirestoreService` con CRUD + seed (85 productos) | 2026-05-18 |
| MVP-04 | Crear widgets: `ProductoCard`, `CategoriaChip`, `CarritoBadge` | 2026-05-18 |
| MVP-05 | Crear `ProductosScreen` (búsqueda + categorías + grid) | 2026-05-18 |
| MVP-06 | Crear `CarritoScreen` (items + cantidades + total) | 2026-05-18 |
| MVP-07 | Crear `ConfiguracionScreen` (CRUD prueba + seed) | 2026-05-18 |
| MVP-08 | Crear `HomeScreen` con BottomNavigationBar | 2026-05-18 |
| MVP-09 | Actualizar `main.dart` con Firebase init + tema | 2026-05-18 |
| MVP-10 | `flutter analyze` — 0 errores ✅ | 2026-05-18 |

---

## 🔴 BLOQUEADO

| ID | Tarea | Razón |
|----|-------|-------|
| — | — | — |

---

### Notas del Sprint
- **Objetivo del Sprint MVP**: Tener la app funcional con catálogo de productos desde Firestore, búsqueda, carrito de compras, y función de prueba CRUD en configuración.
- **Criterio de aceptación**: La app muestra productos cargados del datasheet, el usuario puede buscar, filtrar por categoría, agregar al carrito, y desde configuración se puede ejecutar CRUD contra Firestore.
