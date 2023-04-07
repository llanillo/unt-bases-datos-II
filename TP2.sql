-- Ejercicio nro. 3:
-- Para facilitar las búsquedas cree los índices necesarios en toda la base de datos (analice
-- minuciosamente el o los campos por los cuales se realizarán las búsquedas).

-- TABLA CAMA
create index index_id_habitacion_cama on cama(id_habitacion);
create index index_estado_rep_cama on cama(estado) where estado like 'EN REPARACION';
create index index_estado_servicio_cama on cama(estado) where estado like 'FUERA DE SERVICIO';

-- TABLA CARGO
create index index_cargo on cargo(cargo);

-- TABLA CLASIFICACIÓN
create index index_clasificacion on clasificacion(clasificacion);

-- TABLA COMPRA
create index index_id_proveedor_compra on compra(id_proveedor);
create index xindex_id_empleado on compra(id_empleado);

-- TABLA CONSULTA

-- TABLA CONSULTORIO

-- TABLA DIAGNÓSTICO

-- TABLA EMPLEADO

-- TABALA EQUIPO

-- TABLA ESPECIALIDAD

-- TABLA ESTUDIO

-- TABLA ESTUDIO_REALIZADO

-- TABLA FACTURA

-- TABLA HABITACIÓN

-- TABLA INTERNACIÓN

-- TABLA LABORATORIO

-- TABLA MANTENIMIENTO_CAMA

-- YABLA MANTEMINIMIENTO_EQUIPO

-- TABLA MEDICAMENTO

-- TABLA OBRA_SOCIAL

-- TABLA PACIENTE

-- TABLA PAGO

-- TABLA PATOLOGÍA

-- TABLA PERSONA

-- TABLA PROVEEDOR

-- TABLA TIPO_ESTUIDO

-- TABLA TRABAJAN

-- TABLA TRATAMIENTO

-- TABLA TURNO

