# APB GPIO: simulacion y tiempos para XC7Z010-CLG400-1

Este repositorio contiene los fuentes que referencia el proyecto de Vivado en
`../../../ProyectoFinal/APB_Core/APB_Core.xpr`. No se requiere tarjeta fisica.

## Cambios

- Direcciones completas de 32 bits: no se repiten perifericos cada 256 bytes.
- Ventanas sin solapamiento: 0x00-0x7F y 0x80-0xFF.
- Solo el primer periferico esta poblado. Las direcciones restantes completan
  la transferencia con lectura cero y escritura ignorada, sin PSLVERR.
- Reset de afirmacion asincrona y liberacion sincronizada en dos ciclos.
  Esperar al menos tres flancos de PCLK despues de liberar PRESETN antes de start.
- El requester ya no declara puertos GPIO sin uso.
- `apb_gpio_pads.sv` conecta el core con primitivas Xilinx IOBUF. Los inout
  existen solo en esta frontera; el core sigue siendo unidireccional.

## Simulacion en la interfaz de Vivado

Reabrir el proyecto si estaba abierto mientras se configuro desde batch.
`sim_1` tiene top `apb_gpio_tb`: prueba 2, 8 y 32 pines, registros, CDC,
reset y accesos invalidos. `sim_pads` tiene top `apb_gpio_pads_tb`: prueba
entrada externa, salida, lectura del pad, direccion mixta y alta impedancia
con la biblioteca UNISIM de Vivado.

Seleccionar el conjunto de simulacion deseado, ejecutar Behavioral Simulation
y `run all` en la consola de XSim. En ModelSim el comando es `run -all`.
No ejecutar `run_gpio.do` para inspeccion interactiva: ese script sale de ModelSim
al terminar. La pausa por $finish es normal.

Para repetir ambas pruebas con XSim desde una consola con Vivado disponible:

```
vivado -mode batch -source scripts/simulate_xsim.tcl
```

## Analisis de tiempos del bloque

```
vivado -mode batch -source scripts/timing_ooc.tcl
```

Ejecuta sintesis, colocacion y ruteo de `apb_top`, con GpioWidth=8, en modo
out-of-context para xc7z010clg400-1. Es una evaluacion del bloque, no una
implementacion completa de la placa. Los reportes quedan en
`reports/timing_150mhz/` junto con el checkpoint ruteado.

`constraints/apb_150mhz.xdc` define periodo de 6.666667 ns, incertidumbre
de 0.100 ns y un presupuesto supuesto de E/S sincronas de 1 ns maximo,
0 ns minimo. Estos presupuestos son un contrato de evaluacion y no datos
medidos de la Zybo. Se exceptua la entrada asincrona de reset y solamente
la ruta gpio_i a la primera etapa del sincronizador; la segunda etapa y
la distribucion del reset sincronizado permanecen sujetas a analisis.

El script elige un sitio BUFGCTRL disponible como supuesto de origen del reloj
para la estimacion OOC; no representa una asignacion fisica de la placa. Sin
ubicaciones de las conexiones del bloque, las rutas hacia y desde los puertos
no tienen un ruteo completo. Consultar tambien `internal_timing.rpt` para
separar los caminos entre registros de las interfaces externas. Un margen
interno positivo no equivale al cierre de tiempos de un sistema completo.
El reporte CDC omite entradas sin reloj de origen: no constituye por si solo
una certificacion de las entradas asincronas GPIO.

El XDC se carga desde el script OOC y no se agrega como restriccion de placa
al proyecto original. No hay asignaciones de pines, Clocking Wizard ni bitstream.
La simulacion suministra el reloj directamente. Revisar setup, hold, CDC,
metodologia y rutas sin restricciones antes de interpretar el resultado.

Las simulaciones digitales no modelan metastabilidad analogica ni garantizan
muestreo coherente de un bus externo de varios bits. El uso de dos etapas
por pin es para entradas GPIO independientes. Interrupciones siguen reservadas.

## Resultados verificados (16 de septiembre de 2026)

- ModelSim: PASS para 2, 8 y 32 GPIO; cero errores y advertencias del diseno.
- Vivado XSim: PASS para esos tres anchos y para el wrapper con IOBUF UNISIM.
  Se corrigio la precision temporal del testbench para ambos simuladores.
- Sintesis y ruteo OOC completados para 8 GPIO: 34 LUT y 86 registros.
- Peor margen de setup global: +1.826 ns; hold global: -1.309 ns.
- Peor hold entre registros del bloque: +0.116 ns.
- Recovery/removal del reset sincronizado: +2.553 / +0.645 ns.
- Cero endpoints internos sin restricciones y cero registros sin reloj.
  Nueve entradas asincronas estan exceptuadas explicitamente (reset y 8 GPIO).
- Metodologia: 42 advertencias TIMING-15 por hold de entradas sincronas.

El cierre temporal completo NO esta aprobado. La peor violacion va de
addr_in[0] al registro PADDR del requester. Las rutas de interfaz OOC carecen
de ubicaciones fisicas y se evaluan bajo presupuestos supuestos; no deben
presentarse como tiempos de placa. El script termina con error intencionalmente
si setup u hold fallan, despues de guardar todos los reportes.

Para cerrar esa parte en una evaluacion sin tarjeta se necesita integrar una
fuente/destino sincronicos concretos (por ejemplo, un controlador registrado
de prueba dentro de la FPGA) y evaluar el conjunto con su distribucion real
del reloj. No se han relajado los presupuestos ni agregado falsas rutas a
las entradas sincronas para ocultar las violaciones.

## Pendientes
- 1. Cerrar tiempos a 150 MHz. El documento registra setup positivo, pero hold global de −1.309 ns. Falta integrar una fuente y un destino síncronos concretos y repetir el análisis del conjunto.
- 2. Recompilar y verificar ModelSim desde cero. El transcript tiene PASS, pero también 13 advertencias, mientras el documento indica cero. Hay que actualizar la evidencia con los fuentes actuales.
- 3. Preparar un README con arquitectura, mapa de registros y pasos para reproducir simulación y síntesis.
Las simulaciones funcionales y del wrapper IOBUF ya están documentadas como aprobadas. Pines y bitstream solo faltarían si la entrega exige probar en tarjeta; el alcance documentado no la requiere.