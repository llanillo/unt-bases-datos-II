-- Ejercicio nro. 1:
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes
-- tareas:
-- a) Escriba un procedimiento almacenado (SP) para agregar registros a la tabla persona. Reciba
-- todos los parámetros necesarios excepto el id (max + 1) que se deberá obtener dentro del SP.
-- Muestre un mensaje de error si no se pudo realizar. Nombre sugerido: persona_alta.


-- b) Escriba un SP para agregar registros en la tabla empleado, pase todos los campos por
-- parámetro, respecto a los campos que son FK pase el DNI de la persona, el nombre de la
-- especialidad y el nombre del cargo. Verifique que dichos datos existan para poder hacer el alta.
-- Nombre sugerido: empleado_alta.

-- c) Realice un SP que permita modificar el saldo de una factura. Debe recibir como parámetro el
-- id de la factura y el monto que se pagó que deberá ser descontado del saldo. Verifique que el
-- número de factura exista (de momento no es necesario ningún otro control). Nombre suerido:
-- factura_modifica_saldo.

-- d) Escriba un SP para modificar el precio de la tabla medicamento. La función debe recibir por
-- parámetro, el nombre de un laboratorio y el porcentaje de aumento. Verifique que el
-- laboratorio exista y modifique todos los medicamentos de ese laboratorio. Nombre sugerido:
-- medicamento_modifica_por_laboratorio.

-- e) Realice un SP para eliminar un medicamento según su nombre. Recuerde que puede estar
-- referenciado en otras tablas por lo que deberá hacer los delete necesarios para poder eliminar
-- el medicamento. Nombre sugerido: medicamento_eliminar


-- Ejercicio nro. 2:
-- Realice los siguientes procedimientos almacenados para que muestren la información solicitada.
-- a) Un SP que muestre el nombre y apellido de un paciente según un DNI ingresado. Nombre
-- sugerido: paciente_obtener.
-- b) Un SP que muestre el precio y stock de un medicamente. Debe recibir como parámetro el
-- nombre del medicamento. Nombre sugerido: medicamento_precio_stock.
-- c) Escriba un SP que muestre el total adeudado (campo saldo de las facturas) por un paciente,
--     según un número de DNI ingresado. Nombre sugerido: paciente_deuda.
--
-- d) Realice un SP que muestre la cantidad de veces que una cama estuvo en mantenimiento, se
-- debe mandar como parámetro el id de la cama. Nombre sugerido:
-- cama_cantidad_mantenimiento.
-- Ejercicio nro. 3:
-- Realice los siguientes procedimientos almacenados utilizando cursores.
-- a) Realice un SP donde se listen todas las obras sociales con toda su información. Nombre
-- sugerido: obra_social_listado.
-- b) Realice un SP donde se listen todas las camas cuyo estado sea “OK”. Nombre sugerido:
-- cama_listado_ok
-- c) Realice un SP que liste todos los medicamentos cuyo stock sea menor que 50. Nombre
-- sugerido: medicamentos_poco_stock.
-- d) Escriba un SP que muestre todas las consultas realizadas en determinada fecha (no haga
-- JOINS). Debe recibir por parámetro la fecha. Nombre sugerido: consulta_listado_por_fecha.
-- e) Realice un SP que muestre el nombre y apellido de un paciente, la fecha y nombre de los
-- estudios que se realizó. Debe recibir como parámetro el DNI del paciente. Nombre sugerido:
-- estudio_por_paciente.
-- f) Realice un SP que muestre el nombre, apellido y teléfono de los empleados que trabajan en
-- un determinado turno. Debe recibir por parámetro el nombre del turno. Nombre sugerido:
-- empleado_por_turno.
--
-- Ejercicio nro. 4:
-- También usando cursores, realice los siguientes procedimientos almacenados con consultas más
-- complejas.
-- a) Un SP con los datos de los medicamentos, de un determinado laboratorio y clasificación,
-- cuyo precio sea menor que el promedio de precios de todos los medicamentos de ese
-- laboratorio y clasificación. Debe recibir por parámetro el nombre del laboratorio y el
-- nombre de la clasificación. Nombre sugerido: medicamento_laboratorio_clasificacion.
-- b) Un SP que muestre los datos de los 10 pacientes a los cuales más se le facturó (tome en
-- cuenta el monto de las facturas). Nombre sugerido: factura_top_ten.