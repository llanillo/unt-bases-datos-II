-- Ejercicio nro. 3:
-- Para facilitar las búsquedas cree los índices necesarios en toda la base de datos (analice
-- minuciosamente el o los campos por los cuales se realizarán las búsquedas).

-- TABLA CAMA
create index index_informacion_cama on cama(tipo, estado);

-- TABLA CARGO
create index index_cargo on cargo(cargo);

-- TABLA CLASIFICACIÓN
create index index_clasificacion on clasificacion(clasificacion);

-- TABLA COMPRA
create index index_fecha_compra on compra(fecha);

-- TABLA CONSULTA
create index index_fecha_hora_consulta on consulta(fecha, hora);

-- TABLA CONSULTORIO
create index index_nombre_ubicacion_consultorio on consultorio(nombre, ubicacion);

-- TABLA DIAGNÓSTICO

-- TABLA EMPLEADO
create index index_fecha_ingreso_empleado on empleado(fecha_ingreso);
create index index_fecha_baja on empleado(fecha_baja);

-- TABALA EQUIPO
create index index_nombre_marca_equipo on equipo(nombre, marca);

-- TABLA ESPECIALIDAD

-- TABLA ESTUDIO

-- TABLA ESTUDIO_REALIZADO
create index index_resultado_estudio_realizado on estudio_realizado(resultado);

-- TABLA FACTURA
create index index_fecha_factura on factura(fecha);

-- TABLA HABITACIÓN
create index index_informacion_habitacion on habitacion(piso, numero);

-- TABLA INTERNACIÓN
create index index_fecha_alta_internacion on internacion(fecha_alta);

-- TABLA LABORATORIO
create index index_nombre_laboratorio on laboratorio(laboratorio);

-- TABLA MANTENIMIENTO_CAMA
create index index_fecha_ingreso_mantenimiento_cama on mantenimiento_cama(fecha_ingreso);

-- YABLA MANTEMINIMIENTO_EQUIPO
create index index_fecha_ingreso_mantenimiento_equipo on mantenimiento_equipo(fecha_ingreso);

-- TABLA MEDICAMENTO
create index index_medicamente on medicamento(nombre, presentacion);

-- TABLA OBRA_SOCIAL
create index index_informacion_obra_social on obra_social(nombre, provincia, localidad);

-- TABLA PACIENTE

-- TABLA PAGO
create index index_fecha_pago on pago(fecha);

-- TABLA PATOLOGÍA
create index index_nombre_patologia on patologia(nombre);

-- TABLA PERSONA
create index index_nombre_completo_persona on persona(apellido, nombre);
create index index_dni_persona on persona(dni);

-- TABLA PROVEEDOR
create index index_informacion_proveedor on proveedor(proveedor, direccion);

-- TABLA TIPO_ESTUIDO

-- TABLA TRABAJAN
create index index_inicio_trabajan on trabajan(inicio);

-- TABLA TRATAMIENTO
create index index_informacion_tratamiento on tratamiento(nombre, fecha_indicacion);

-- TABLA TURNO

