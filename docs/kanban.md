# Kanban Board — Minimarket Wisa App

> Estado actualizado: 2026-06-08
> Leyenda: 🔴 Bloqueado | 🟡 En Progreso | 🟢 Completado | ⚪ Pendiente | 🔵 QA/Revisión

---

## 📋 RESUMEN DE SPRINTS

| Sprint | Nombre | Duración | Objetivo | Estado |
|--------|--------|----------|----------|--------|
| MVP | Sprint Base | Completado ✅ | App funcional con catálogo, carrito y CRUD | 🟢 Completado |
| S1 | Branding Wisa + UI Overhaul | 3-4 días | Adaptar colores/logo Wisa, eliminar headers duplicados, rediseño UI | 🟢 Completado |
| S2 | Auth QoL + Perfil de Usuario | 2-3 días | Auto-login al registrar, módulo de perfil independiente | 🟢 Completado |
| S3 | Scoring & Beneficios | 3-4 días | Módulo de scoring independiente, descuentos, ofertas, beneficios por puntos | 🟢 Completado |
| S4 | Delivery Inteligente | 2-3 días | Cálculo de delivery por km, descuento de delivery por scoring | 🟢 Completado |
| S5 | Real-time + Gestión de Pedidos | 2-3 días | Streams en tiempo real, borrar pedidos cancelados, actualización sin recargar | 🟢 Completado |
| S6 | Polish & QA Final | 2 días | Pruebas, bugs edge-case, optimización, de lints y advertencias | 🟢 Completado |

---

## 🟢 COMPLETADO

| ID | Tarea | Fecha Completada | Notas |
|----|-------|------------------|-------|
| **SETUP** | Configuración base del proyecto | 2026-05-18 | Flutter, Firebase, dependencias. |
| **MVP** | MVP funcional con CRUD | 2026-05-18 | Pantallas básicas y seed. |
| **S1-01** | Integrar logotipo Wisa en la app | 2026-06-08 | Logo integrado en login, appbar, splash. |
| **S1-02** | Rediseñar theme.dart con paleta Wisa | 2026-06-08 | Paleta Crimson/White/Yellow. |
| **S1-03** | Actualizar MinimarketTheme | 2026-06-08 | Colores primarios e HSL refinados. |
| **S1-04** | Eliminar Scaffold/AppBar duplicado | 2026-06-08 | Limpieza en HistorialPedidosScreen. |
| **S1-05** | Rediseñar LoginScreen con logo Wisa | 2026-06-08 | Estética premium carmesí. |
| **S1-06** | Rediseñar RegistroScreen con branding | 2026-06-08 | Estética unificada. |
| **S1-07** | Actualizar BottomNavigationBar | 2026-06-08 | Estilo carmesí y amarillo de acento. |
| **S1-08** | Actualizar colores en pantallas restantes | 2026-06-08 | Sustitución completa de secondaryNavy. |
| **S1-09** | Rediseñar tarjeta de puntos | 2026-06-08 | Gradiente carmesí interactivo. |
| **S1-10** | Actualizar SnackBar, Dialog, Card themes | 2026-06-08 | Consistencia de marca. |
| **S2-01** | Auto-login tras registro | 2026-06-08 | Login directo al crear cuenta. |
| **S2-02** | Crear PerfilScreen independiente | 2026-06-08 | Datos completos, DNI, teléfono y GPS. |
| **S2-03** | Agregar tab Perfil en BottomNav | 2026-06-08 | Reemplaza configuración para usuarios. |
| **S2-04** | Ocultar ConfiguracionScreen en Release | 2026-06-08 | Acceso con kDebugMode en perfil. |
| **S2-05** | Permitir editar datos de perfil | 2026-06-08 | Dialog interactivo con actualización en Firestore. |
| **S2-06** | Mostrar estado de sesión en perfil | 2026-06-08 | Pantalla con invitación a iniciar sesión si es nulo. |
| **S2-07** | Eliminar perfil duplicado en Config | 2026-06-08 | Limpieza de código. |
| **S2-08** | Requerir login antes del Checkout | 2026-06-08 | Redirección con autocompletado de perfil. |
| **S3-01** | Ocultar tarjeta de puntos sin sesión | 2026-06-08 | Corrección de visibilidad condicional. |
| **S3-02** | Pantalla ScoringScreen independiente | 2026-06-08 | Historial de puntos y beneficios Club Caserito. |
| **S3-03** | Lógica de niveles (Vecino, Amigo, Caserito) | 2026-06-08 | Descuentos en productos del 0%, 5% y 10%. |
| **S3-04** | Descuento por canje de puntos | 2026-06-08 | 1 punto = S/ 0.01 de descuento aplicado. |
| **S3-05** | Descuento de delivery por nivel | 2026-06-08 | Delivery gratis progresivo. |
| **S3-06** | Crear pantalla OfertasScreen | 2026-06-08 | Descuentos directos en catálogo. |
| **S3-07** | Mostrar badge de nivel (Bronce, Plata, Oro) | 2026-06-08 | Iconos de estrella con colores según nivel. |
| **S3-08** | Historial de transacciones de puntos | 2026-06-08 | Firestore subcolección `historialPuntos`. |
| **S3-09** | Dialog animado al subir de nivel | 2026-06-08 | Alerta con felicitación tras confirmar compra. |
| **S4-01** | Lógica Haversine para distancia GPS | 2026-06-08 | Distancia real desde la tienda más cercana. |
| **S4-02** | Distancia mostrada en Checkout | 2026-06-08 | Desglose dinámico con kilómetros. |
| **S4-03** | Escala de precios por distancia | 2026-06-08 | 0-2km: S/3, 2-5km: S/5, 5-10km: S/8, >10km: S/12. |
| **S4-04** | Guardar coordenadas GPS en perfil/registro | 2026-06-08 | Geolocator integrado para latitud/longitud. |
| **S4-05** | Descuento de delivery por rango | 2026-06-08 | Amigo: gratis > S/40, Caserito: gratis > S/30. |
| **S4-06** | Círculos de cobertura en UbicacionScreen | 2026-06-08 | Google Maps circles con radios de 3km y 5km. |
| **S5-01** | Pedidos reactivos con StreamBuilder | 2026-06-08 | HistorialPedidosScreen con Firestore listen. |
| **S5-02** | CRUD real de pedidos cancelados | 2026-06-08 | Lógica de cancelación 5 min y borrado físico. |
| **S5-03** | Productos en tiempo real con Streams | 2026-06-08 | ProductosScreen con Firestore stream. |
| **S5-04** | Sincronización de puntos en tiempo real | 2026-06-08 | Escucha de cambios de puntos y nivel. |
| **S5-05** | Actualizar stock de productos en compra | 2026-06-08 | Transacción atómica que disminuye stock. |
| **S5-06** | Indicador de última actualización (Sync Status) | 2026-06-08 | Mensaje de sincronización "Sinc. HH:mm:ss". |
| **S6-01** | Cero errores en `flutter analyze` | 2026-06-08 | Corrección de sintaxis y linter. |
| **S6-02** | Verificación de flujos | 2026-06-08 | Rutas estables y sin crashes. |
| **S6-09** | Carga optimizada de imágenes | 2026-06-08 | Integración de cached_network_image. |

---

## 🐛 BUGS RESUELTOS

| ID | Bug | Estado | Solución |
|----|-----|--------|----------|
| BUG-01 | Tarjeta de puntos se muestra sin sesión | ✅ Resuelto | Se añadió verificación condicional de sesión. |
| BUG-02 | Headers duplicados al embeber historial | ✅ Resuelto | Removido el Scaffold anidado si es embebido. |
| BUG-03 | Registro no hace auto-login | ✅ Resuelto | Navegación directa tras registrar usuario. |
| BUG-04 | Costo de delivery fijo (S/ 5.00) | ✅ Resuelto | Costo calculado con Haversine y escalas por km. |
| BUG-05 | Historial usa Future y requiere recarga manual | ✅ Resuelto | Cambiado a StreamSubscription reactiva en Firestore. |
| BUG-06 | No se pueden eliminar pedidos cancelados | ✅ Resuelto | Añadida acción de borrado en Firestore si cancelado. |
| BUG-07 | Perfil duplicado en configuración | ✅ Resuelto | Datos duplicados depurados. |
| BUG-08 | Stock físico de productos no disminuye | ✅ Resuelto | Transacción para disminuir stock al pagar. |
| BUG-09 | SDD de arquitectura desactualizado | ✅ Resuelto | sdd-master.md reescrito con arquitectura actual. |

---

## 📊 MÉTRICAS DEL PROYECTO

### Archivos de código (lib/)
- **Total:** 29 archivos.
- **Nuevos agregados:** `perfil_screen.dart`, `scoring_screen.dart`, `ofertas_screen.dart`.
- **Dependencias:** `cached_network_image`, `geolocator`, `google_maps_flutter`, `firebase_auth`, `cloud_firestore`.
