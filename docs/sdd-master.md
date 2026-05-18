# SDD — Documento de Diseño de Software
## Minimarket App (Flutter + Firestore)

---

## 1. Introducción

### 1.1 Propósito
Este documento describe la arquitectura, el diseño y las especificaciones técnicas de la aplicación móvil **Minimarket**, una app de catálogo y carrito de compras para una tienda de abarrotes/bodega peruana. Desarrollada con Flutter y Cloud Firestore como base de datos en la nube.

### 1.2 Alcance
La aplicación está orientada a la **vista del usuario final** (cliente del minimarket). Permite navegar un catálogo de productos organizado por categorías, buscar productos, agregarlos a un carrito de compras y visualizar la ubicación de la tienda.

### 1.3 Metodología
Se utiliza **Spec Driven Development (SDD)**: toda funcionalidad se documenta primero en este documento maestro y en los documentos auxiliares antes de ser implementada.

---

## 2. Arquitectura del Sistema

### 2.1 Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Dart) |
| Base de Datos | Cloud Firestore (Firebase) |
| Autenticación | Firebase (futuro) |
| Mapas | Google Maps Flutter (futuro) |
| Geolocalización | Geolocator (futuro) |
| Plataforma objetivo | Android (SDK 24+) |

### 2.2 Arquitectura de Carpetas

```
lib/
├── main.dart                    # Punto de entrada, inicialización Firebase
├── config/
│   └── theme.dart               # Paleta de colores y tema global
├── models/
│   └── producto.dart            # Modelo de datos del producto
├── services/
│   └── firestore_service.dart   # CRUD de Firestore
├── screens/
│   ├── home_screen.dart         # Pantalla principal con navegación
│   ├── productos_screen.dart    # Catálogo de productos con búsqueda
│   ├── carrito_screen.dart      # Pantalla del carrito de compras
│   └── configuracion_screen.dart # Configuración + función CRUD de prueba
└── widgets/
    ├── producto_card.dart       # Card individual de producto
    ├── categoria_chip.dart      # Chip de filtro por categoría
    └── carrito_badge.dart       # Badge animado del carrito en AppBar
```

### 2.3 Diagrama de Flujo de la App

```
┌─────────────────┐
│   Splash/Init    │──► Firebase.initializeApp()
│   (main.dart)    │
└────────┬────────┘
         ▼
┌─────────────────┐
│   HomeScreen     │──► BottomNavigationBar
│  (Tab principal) │
└────────┬────────┘
         │
    ┌────┼────────────────┐
    ▼    ▼                ▼
┌────────┐ ┌────────────┐ ┌──────────────────┐
│Productos│ │  Carrito    │ │ Configuración    │
│ Screen  │ │  Screen    │ │ Screen           │
│         │ │            │ │ (CRUD prueba +   │
│ -Lista  │ │ -Items     │ │  seed Firestore) │
│ -Buscar │ │ -Total     │ │                  │
│ -Filtro │ │ -Cantidad  │ │                  │
└─────────┘ └────────────┘ └──────────────────┘
```

---

## 3. Modelo de Datos

### 3.1 Colección `productos` (Firestore)

| Campo       | Tipo     | Descripción                              |
|-------------|----------|------------------------------------------|
| `nombre`    | String   | Nombre completo del producto             |
| `descripcion` | String | Descripción corta del producto           |
| `categoria` | String   | Categoría principal (ej: "Bebidas / Gaseosas") |
| `precio`    | double   | Precio en Soles (S/)                     |

### 3.2 Modelo Dart `Producto`

```dart
class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
}
```

---

## 4. Diseño Visual

### 4.1 Paleta de Colores

| Rol               | Color                | Código HEX  |
|--------------------|----------------------|-------------|
| Primario           | Amarillo Dorado      | `#FFC107`   |
| Primario Oscuro    | Amarillo Ámbar       | `#FFA000`   |
| Secundario         | Azul Oscuro Navy     | `#1A237E`   |
| Secundario Claro   | Azul Índigo          | `#283593`   |
| Fondo              | Blanco Humo          | `#FAFAFA`   |
| Superficie/Card    | Blanco               | `#FFFFFF`   |
| Texto Principal    | Azul Oscuro          | `#1A237E`   |
| Texto Secundario   | Gris                 | `#757575`   |
| Acento/CTA         | Amarillo Brillante   | `#FFCA28`   |
| Error              | Rojo                 | `#D32F2F`   |

### 4.2 Tipografía
- Fuente primaria: **Roboto** (default de Material Design)
- Títulos: Bold, tamaño 20-24
- Cuerpo: Regular, tamaño 14-16
- Precios: Bold, tamaño 16-18, color primario

### 4.3 Componentes Visuales Clave
- **AppBar**: Fondo azul oscuro (`#1A237E`), texto e iconos en amarillo/blanco
- **Cards de producto**: Elevación sutil, borde redondeado (12px), precio destacado en amarillo
- **BottomNavigationBar**: Azul oscuro, ícono activo en amarillo
- **Botones**: Fondo amarillo con texto azul oscuro
- **Barra de búsqueda**: Borde redondeado, ícono de búsqueda en azul

---

## 5. Especificaciones de Pantallas (MVP)

### 5.1 ProductosScreen (Pantalla Principal)
- **Funcionalidad**: Listar todos los productos desde Firestore, filtrar por categoría, buscar por nombre
- **Elementos UI**:
  - AppBar con título "Minimarket" y badge del carrito animado
  - Barra de búsqueda con filtro en tiempo real
  - Chips horizontales de categorías (scroll horizontal)
  - Grid/Lista de ProductoCards
- **Interacciones**:
  - Tap en producto → agrega al carrito con SnackBar de confirmación
  - Animación de rebote (scale) en el ícono del carrito al agregar
  - Búsqueda local filtrando por nombre

### 5.2 CarritoScreen
- **Funcionalidad**: Mostrar productos agregados, cantidades, total
- **Elementos UI**:
  - Lista de items del carrito con cantidad y precio unitario
  - Botón para eliminar items
  - Resumen con total en la parte inferior
- **Interacciones**:
  - Incrementar/decrementar cantidad
  - Eliminar item con deslizar (Dismissible)

### 5.3 ConfiguracionScreen
- **Funcionalidad**: Pantalla de configuración con funciones de prueba para desarrollo
- **Elementos UI**:
  - Botón "Cargar Productos Iniciales" → ejecuta seed del datasheet a Firestore
  - Sección CRUD de prueba:
    - Listar todos los documentos de la colección `productos`
    - Crear un producto manualmente
    - Editar un producto existente
    - Eliminar un producto
  - Indicador de estado (cargando, éxito, error)
- **Nota**: Esta pantalla será removida o protegida en versiones de producción

---

## 6. Servicios

### 6.1 FirestoreService
Clase centralizada para todas las operaciones con Firestore:

```dart
class FirestoreService {
  // Colección de productos
  final CollectionReference productosCollection;
  
  // CRUD
  Future<List<Producto>> obtenerProductos();
  Future<void> agregarProducto(Producto producto);
  Future<void> actualizarProducto(Producto producto);
  Future<void> eliminarProducto(String id);
  
  // Seed
  Future<void> cargarProductosIniciales(List<Producto> productos);
}
```

---

## 7. Fases de Desarrollo

### Fase 1 — MVP (Actual)
- [x] Configuración del proyecto Flutter
- [x] Configuración de Firebase/Firestore
- [ ] Tema y paleta de colores
- [ ] Modelo Producto
- [ ] FirestoreService (CRUD completo)
- [ ] Seed de datos del datasheet a Firestore
- [ ] ProductosScreen (lista, búsqueda, filtro por categoría)
- [ ] CarritoScreen (lista de items, total)
- [ ] ConfiguracionScreen (CRUD de prueba + botón seed)
- [ ] HomeScreen con BottomNavigationBar
- [ ] Animación del carrito

### Fase 2 — Mejoras UX (Futura)
- [ ] Google Maps con ubicación de la tienda
- [ ] Ruta del usuario a la tienda
- [ ] Imágenes de productos
- [ ] Autenticación de usuario
- [ ] Historial de pedidos

---

## 8. Dependencias del Proyecto

```yaml
dependencies:
  flutter: sdk
  firebase_core: ^4.9.0
  cloud_firestore: ^6.4.1
  cupertino_icons: ^1.0.8
```

---

*Documento vivo — se actualiza conforme avanza el desarrollo.*
*Última actualización: 2026-05-18*
