-- EJERCICIO N° 1: STORED PROCEDURE
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes tareas:
-- a) Escriba el procedimiento almacenado sp_calcula_costo, el mismo recibirá como parámetros el id_paciente,
-- id_cama, fecha_inicio y fecha_alta. El procedimiento debe calcular el costo de la internación multiplicando la
-- cantidad de días por el precio de la habitación. Para facilitar el trabajo, no realice los controles de existencia de
-- pacientes, cama ni de fechas, solo haga el cálculo del total.
-- Nota1: se aconseja usar CREATE PROCEDURE sp_calcula_costo (int, int, date, date, out total Numeric) AS $$
--     Nota2: para calcular la cantidad de días puede usar dif:= EXTRACT(DAY FROM age(date(fecha2),date(fecha1)))

create or replace procedure sp_calcula_costo(p_id_paciente int, p_id_cama int, p_fecha_inicio date, p_fecha_alta date,
                                             out p_total numeric)
as
$$
declare
    internacion_buscada       internacion%rowtype;
    costo_habitacion          numeric;
    cantidad_dias_internacion int;
begin

    select i.*
    from internacion i
             inner join paciente pa using (id_paciente)
             inner join persona p on pa.id_paciente = p.id_persona
    where pa.id_paciente = p_id_paciente
      and i.fecha_inicio = p_fecha_inicio
    into internacion_buscada;

    select h.precio
    from habitacion h
             inner join cama c using (id_habitacion)
             inner join internacion i using (id_cama)
             inner join paciente pa using (id_paciente)
    where pa.id_paciente = p_id_paciente
      and c.id_cama = p_id_cama
      and i.fecha_inicio = p_fecha_inicio
    into costo_habitacion;

    cantidad_dias_internacion :=
            extract(day from age(date(internacion_buscada.fecha_inicio), date(internacion_buscada.fecha_alta)));
    p_total := cantidad_dias_internacion * costo_habitacion;

end;
$$
    language plpgsql;



-- b) Escriba el procedimiento almacenado sp_internacion; el mismo recibirá como parámetros el nombre y apellido
-- de un paciente, id_cama y una fecha. Si en la tabla internación no existe un registro con el paciente, la cama
-- ingresada y sin datos de la fecha de alta, deberá realizar un nuevo ingreso usando la fecha recibida como
-- parámetro, como fecha_inicio y todos los campos restantes se insertan en null. Por el contrario, si hay un registro
-- con el paciente, la cama y la fecha de alta no tiene datos, deberá modificar el registro de la siguiente manera:
-- el campo fecha de alta con la fecha ingresada, el campo hora con la hora del sistema y el campo costo deberá ser
-- calculado usando la sp_calcula_costo. Realice todos los controles, y tenga en cuenta que hay camas que están
-- fuera de servicio.
-- Nota1: se aconseja usar CREATE PROCEDURE sp_internacion(text, text, integer, date) AS $$
--     Nota2: se aconseja usar Variable = (SELECT sp_calcula_costo(arg1, arg2, arg3, arg4, NULL))


-- EJERCICIO N° 2: TRIGGERS
--
-- Realice los siguientes triggers, analizando cuidadosamente qué acción (INSERT, UPDATE o DELETE), sobre qué tabla y
-- cuándo (BEFORE o AFTER) se deben activar los mismos:
-- a) Cada vez que se inserte un registro en la tabla estudiorealizado, se debe insertar un registro en una nueva tabla
-- llamada estudios_x_empleados, la misma tendrá los siguientes campos, id_empleado, nombre y apellido del
-- empleado, el id y nombre del estudio que realizó y un campo cantidad, el cual guardará la cantidad de estudios
-- que realizó el empleado y la fecha en la que se realizó el estudio. Si en la tabla estudios_x_empleados existe un
-- registro que contenga el id_empleado y el id_estudio, deberá aumentar la cantidad de estudio en 1 y cambiar la
-- fecha por la del último estudio realizado, si no coincide alguno de los id, deberá insertar un nuevo registro con los
-- nuevos datos.


-- b) Audite la tabla empleados solo cuando se modifique el campo sueldo por un sueldo mayor. Se debe guardar un
-- registro en la tabla audita_empleado. Los datos que debe almacenar la nueva tabla serán: id, usuario, la fecha
-- cuando se produjo la modificación, el id, nombre y apellido del empleado, el sueldo antes de la modificación y el
-- sueldo después de la modificación, además de un campo llamado porcentaje, que guardará el porcentaje de
-- aumento.
--  Nota2: porcentaje = ((sueldo_aumentado - sueldo_sin_aumento) / sueldo_sin_aumento) * 100


