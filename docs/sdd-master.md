# SDD — Documento de Diseño de Software
## Minimarket Wisa App (Flutter + Firestore + Google Maps)

---

## 1. Introducción

### 1.1 Propósito
Este documento describe la arquitectura, el diseño y las especificaciones técnicas completas de la aplicación móvil **Minimarket Wisa**, una plataforma móvil premium de comercio electrónico para una bodega/minimarket peruano en Huancayo.

### 1.2 Alcance
La aplicación cubre el ciclo completo del cliente:
- Registro e inicio de sesión con captura de ubicación GPS.
- Catálogo interactivo de productos con actualización en tiempo real, búsqueda y filtrado por categoría.
- Sección de ofertas exclusivas y promociones.
- Club Caserito (Módulo de Scoring) con niveles de fidelización (Vecino, Amigo de la casa, El Caserito), beneficios progresivos y canje de puntos por descuentos reales.
- Carrito de compras y Checkout inteligente que calcula la distancia real por GPS a la tienda más cercana usando la fórmula Haversine, aplicando tarifas de delivery escalonadas y descuentos correspondientes.
- Seguimiento de pedidos y visualización de rutas óptimas en Google Maps con zonas de cobertura translúcidas.
- Historial de pedidos reactivo con opción de cancelación y eliminación física de pedidos cancelados dentro de los primeros 5 minutos.

### 1.3 Metodología
Se utiliza **Spec Driven Development (SDD)** combinada con metodologías ágiles. La arquitectura de datos y la UI son validadas constantemente contra las especificaciones del documento de diseño.

---

## 2. Arquitectura del Sistema

### 2.1 Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Dart) |
| Base de Datos | Cloud Firestore (Firebase) |
| Autenticación | Firebase Auth |
| Mapas | Google Maps Flutter |
| Geolocalización | Geolocator (Fórmula Haversine local) |
| Caché de Imágenes| Cached Network Image |
| Plataforma objetivo | Android (SDK 24+) |

### 2.2 Estructura de Directorios

```
lib/
├── main.dart                    # Punto de entrada, inicialización Firebase
├── config/
│   ├── theme.dart               # Paleta de colores Crimson/Yellow/White y tema global
│   └── maps_config.dart         # Ubicaciones de tiendas Wisa y coordenadas de referencia
├── models/
│   ├── producto.dart            # Modelo de producto
│   ├── usuario.dart             # Modelo de usuario (incluye DNI, puntos y coordenadas)
│   └── pedido.dart              # Modelo de pedido
├── services/
│   ├── firestore_service.dart   # CRUD de productos y carga de ofertas
│   ├── delivery_service.dart    # Gestión de pedidos en real-time y tarifas de delivery
│   └── directions_service.dart  # Conexión con Directions API de Google Maps
├── screens/
│   ├── home_screen.dart         # Navegación principal (Catálogo, Ubicación, Historial, Perfil)
│   ├── productos_screen.dart    # Catálogo de productos interactivo en tiempo real
│   ├── ofertas_screen.dart      # Lista de ofertas exclusivas de la colección "ofertas"
│   ├── scoring_screen.dart      # Club Caserito (niveles, beneficios y transacciones de puntos)
│   ├── carrito_screen.dart      # Gestión de productos agregados
│   ├── checkout_screen.dart     # Pago, cálculo de delivery y transacciones de stock/puntos
│   ├── seguimiento_screen.dart  # Vista de estado del pedido con mapa y temporizador
│   ├── historial_pedidos_screen.dart # Listado reactivo de pedidos pasados y activos
│   ├── perfil_screen.dart       # Gestión de datos, GPS e inicio/cierre de sesión
│   ├── login_screen.dart        # Autenticación de usuarios
│   └── registro_screen.dart     # Creación de cuentas con auto-login y captura GPS
└── widgets/
    ├── carrito_badge.dart       # Icono animado del carrito
    ├── categoria_chip.dart      # Chips de filtrado
    ├── producto_card.dart       # Card de producto con diseño premium
    ├── producto_detalle.dart    # BottomSheet de detalle
    └── producto_imagen.dart     # Renderizador de imágenes con CachedNetworkImage
```

---

## 3. Modelo de Datos y Colecciones de Firestore

### 3.1 Colección `usuarios`
Documentos identificados por el **DNI** del usuario:
- `uid` (String): ID de autenticación.
- `dni` (String): DNI del usuario.
- `nombreCompleto` (String): Nombre del cliente.
- `email` (String): Correo electrónico.
- `telefono` (String): Celular de contacto.
- `direccion` (String): Dirección de entrega.
- `referencia` (String): Referencia del domicilio.
- `puntosAcumulados` (int): Puntos de fidelidad.
- `latitud` (double): Latitud de entrega.
- `longitud` (double): Longitud de entrega.

#### Subcolección `usuarios/{dni}/historialPuntos`
Registros de transacciones de puntos:
- `puntos` (int): Cantidad (positivo para ganados, negativo para canjes).
- `motivo` (String): Razón de la transacción (Ej: "Compra de pedido", "Canje por descuento").
- `fecha` (Timestamp): Fecha y hora del evento.

### 3.2 Colección `productos`
Catálogo de la tienda:
- `nombre` (String): Nombre del artículo.
- `descripcion` (String): Detalles.
- `categoria` (String): Categoría del producto.
- `precio` (double): Precio de venta.
- `imagenUrl` (String): Dirección de la imagen.
- `stock` (int): Cantidad física disponible.
- `disponible` (bool): Flag de disponibilidad.

### 3.3 Colección `ofertas`
Productos con descuentos especiales:
- `nombre`, `descripcion`, `categoria`, `imagenUrl` (String).
- `precioOriginal` (double).
- `precioOferta` (double).
- `descuentoPorcentaje` (int).

### 3.4 Colección `pedidos`
Gestión de compras:
- `id` (String): Auto-generado.
- `userId` (String): UID del cliente.
- `dniUsuario` (String): DNI de referencia.
- `nombreCliente`, `telefono`, `direccion`, `referencia` (String).
- `items` (List<Map>): Productos y cantidades.
- `subtotal`, `costoDelivery`, `descuentoAplicado`, `total` (double).
- `puntosGanados`, `puntosCanjeados` (int).
- `estado` (String): "pendiente", "en_camino", "entregado", "cancelado".
- `metodoPago` (String): "efectivo", "tarjeta", "yape".
- `fechaCreacion` (Timestamp).

---

## 4. Diseño Visual (Branding Wisa)

### 4.1 Paleta de Colores Corporativa
- **Color Primario (Crimson Red)**: `#C62828` y `#D32F2F` — Aporta energía y apetito visual.
- **Color Secundario (Gris / Blanco Humo)**: `#FAFAFA` y `#F5F5F5` — Superficies limpias.
- **Color de Acento (Yellow)**: `#FFC107` y `#FFA000` — Resalta botones CTA y puntos.
- **Color de Éxito (Green)**: `#2E7D32` — Mensajes de confirmación y stock disponible.

### 4.2 Tipografía y Elementos Visuales
- **Tipografía**: Roboto / Sans-serif con jerarquías claras (Títulos Bold de 18-22px, cuerpo regular de 13-14px).
- **Cards**: Bordes redondeados de 14-16px, elevación ligera, sombras difusas y micro-animaciones en estados hover.
- **Imágenes**: Uso sistemático de `CachedNetworkImage` para almacenamiento en caché, con placeholders animados y fallbacks de error en gris suave.

---

## 5. Especificaciones de Lógica de Negocio

### 5.1 Club Caserito (Scoring)
Los usuarios acumulan puntos por cada compra realizada (S/ 1.00 de subtotal neto = 1 punto ganado).
- **Canje**: Cada 1 punto canjeado equivale a S/ 0.01 de descuento adicional en el total de la compra (incluyendo delivery).
- **Niveles de Socio**:
  - **Vecino (0 a 49 pts)**: Tarifa normal de delivery. 0% de descuento en subtotal.
  - **Amigo de la casa (50 a 149 pts)**: 5% de descuento en el subtotal. 50% de descuento en delivery (o delivery gratis en compras superiores a S/ 40.00).
  - **El Caserito (150+ pts)**: 10% de descuento en el subtotal. 100% de descuento en delivery (siempre gratis en compras superiores a S/ 30.00).

### 5.2 Delivery Inteligente por Geolocalización
Usa las coordenadas GPS (`latitud`/`longitud`) del perfil del usuario para calcular la distancia en kilómetros a la sucursal de Minimarket Wisa más cercana usando la fórmula Haversine:
- **0 a 2 km**: S/ 3.00
- **2 a 5 km**: S/ 5.00
- **5 a 10 km**: S/ 8.00
- **Más de 10 km**: S/ 12.00
Se aplican posteriormente los descuentos de delivery por nivel de Club Caserito detallados en la sección 5.1.

### 5.3 Gestión Reactiva (Real-time) y Transacciones
- Los catálogos de productos e historiales de pedidos se recargan automáticamente usando Streams en tiempo real de Firestore, reflejando inmediatamente cualquier cambio en el backend.
- La confirmación de pedidos se realiza en una transacción de Firestore que decrementa el stock del producto en la base de datos (marcando `disponible: false` si el stock llega a 0) y registra la transacción de puntos en la subcolección del usuario.
- Si un pedido tiene estado "pendiente", el usuario tiene un plazo de **5 minutos** para cancelarlo y eliminarlo físicamente tanto de su historial como de Firestore para liberar el stock reservado.

---

*Última actualización: 2026-06-08 (Completado Sprint S6).*
