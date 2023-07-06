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
    internacion_buscada       record;
    cantidad_dias_internacion int;
begin

    select i.fecha_inicio, i.fecha_alta, h.precio
    from habitacion h
             inner join cama c using (id_habitacion)
             inner join internacion i using (id_cama)
             inner join paciente pa using (id_paciente)
    where pa.id_paciente = p_id_paciente
      and c.id_cama = p_id_cama
      and i.fecha_inicio = p_fecha_inicio
      and i.fecha_alta = p_fecha_alta
    into internacion_buscada;

    cantidad_dias_internacion :=
            extract(day from age(date(internacion_buscada.fecha_inicio), date(internacion_buscada.fecha_alta)));
    p_total := cantidad_dias_internacion * internacion_buscada.precio;

exception
    when others then
        raise exception 'Ocurrió un problema al ejecutar el procedimiento %', SQLERRM;
end;
$$
    language plpgsql;

-------------------------------------- PRUEBAS--------------------------------------

begin;

call sp_calcula_costo(26909, 70, '2019-01-31', '2019-02-10', null);

rollback;

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

create or replace procedure sp_internacion(p_nombre text, p_apellido text, p_id_cama int, p_fecha date)
as
$$
declare
    existe_paciente     boolean;
    existe_cama         boolean;
    existe_internacion  boolean;
    costo_final         numeric;
    id_paciente_buscado int;
begin
    -------------------------------------- INICIO CONTORLES --------------------------------------
    if p_nombre is null or p_nombre = '' then
        raise exception 'El nombre ingresado es inválido';
    end if;

    if p_apellido is null or p_apellido = '' then
        raise exception 'El apellido ingresado es inválido';
    end if;

    if p_id_cama is null then
        raise exception 'El id_cama ingresado es inválido';
    end if;

    if p_fecha is null then
        raise exception 'La fecha ingresado es inválida';
    end if;

    select exists(select 1 from persona p where p.nombre like p_nombre and p.apellido like p_apellido)
    into existe_paciente;

    if not existe_paciente then
        raise exception 'No existe la persona buscada';
    end if;

    select exists(select 1 from cama c where c.id_cama = p_id_cama) into existe_cama;

    if not existe_cama then
        raise exception 'No existe la cama buscada';
    end if;

    if (select c.estado from cama c where c.id_cama = p_id_cama) in ('FUERA DE SERVICIO', 'EN REPARACION') then
        raise exception 'La cama seleccionada esta fuera de servicio';
    end if;

    -------------------------------------- FIN CONTORLES --------------------------------------

    -------------------------------------- INICIO PROCEDIMIENTO --------------------------------------

    ----------------- BUSCA INTERNACIÓN CON LOS PARÁMETROS -----------------
    select exists(select 1
                  from persona p
                           inner join paciente pa on p.id_persona = pa.id_paciente
                           inner join internacion i using (id_paciente)
                           inner join cama c using (id_cama)
                  where c.id_cama = p_id_cama
                    and p.nombre like p_nombre
                    and p.apellido like p_apellido
                    and i.fecha_alta is null)
    into existe_internacion;

    ----------------- BUSCA PACIENTE CON LOS PARÁMETROS -----------------
    select id_persona
    from persona p
    where p.nombre like p_nombre
      and p.apellido like p_apellido
    limit 1
    into id_paciente_buscado;

    if existe_internacion then

        ---- COMENTADO
--         costo_final := (select sp_calcula_costo(id_paciente_buscado, p_id_cama, (select i.fecha_inicio
--                                                                                  from persona p
--                                                                                           inner join paciente pa on p.id_persona = pa.id_paciente
--                                                                                           inner join internacion i using (id_paciente)
--                                                                                           inner join cama c using (id_cama)
--                                                                                  where c.id_cama = p_id_cama
--                                                                                    and p.nombre like p_nombre
--                                                                                    and p.apellido like p_apellido
--                                                                                    and i.fecha_alta is null),
--                                                 p_fecha, costo_final));
--
        update internacion i
        set fecha_alta = p_fecha,
            hora       = current_time,
            costo      = 234
        where i.id_paciente = id_paciente_buscado
          and i.id_cama = p_id_cama
          and i.fecha_alta is null;

    else

        insert into internacion
        values (id_paciente_buscado, p_id_cama, p_fecha, 0, null, null, null);

    end if;

exception
    when others then
        raise exception 'Ocurrió un problema al ejecutar el procedimiento %', SQLERRM;

end;
$$ language plpgsql;


-------------------------------------- PRUEBAS--------------------------------------

begin;

-- PRUEBA CAMA FUERA DE SERVICIO
call sp_internacion('MABEL ELISABETH', 'BUSTOS', 3, '2019-01-01');

-- PRUEBA PERSONA INEXISTENTE
call sp_internacion('ELISABETH', 'BUSTOS', 3, '2019-01-01');

-- PRUEBA QUE DEBERÍA FUNCIONAR
call sp_internacion('MABEL ELISABETH', 'BUSTOS', 1, '2019-01-01');

rollback;

-------------------------------------- PRUEBAS--------------------------------------

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

create or replace function fn_alta_estudio_realizado() returns trigger
as
$tr_alta_estudio_realizado$
declare
    existe_estudio       boolean;
    informacion_empleado record;
    informacion_estudio  estudio%rowtype;
begin

    ----------------- CREA TABLA EN CASO DE NO EXISTIR -----------------
    create table if not exists estudios_x_empleados
    (
        id_empleado    int,
        nombre         varchar(150),
        apellido       varchar(150),
        id_estudio     int,
        nombre_estudio varchar(150),
        cantidad       int default 1,
        fecha          date
    );

    ----------------- BUSCA ESTUDIO REALILZADO EN LA TABLA DE AUDITADO -----------------
    select exists(select 1
                  from estudios_x_empleados er
                  where er.id_empleado = new.id_empleado
                    and er.id_estudio = new.id_estudio)
    into existe_estudio;

    if existe_estudio then
        update estudios_x_empleados ee
        set cantidad = cantidad + 1,
            fecha    = new.fecha
        where ee.id_empleado = new.id_empleado
          and ee.id_estudio = new.id_estudio;
    else
        ----------------- BUSCA LOS DATOS DE LA PERSONA QUE HACE EL ESTUDIO -----------------
        select p.nombre, p.apellido from persona p where p.id_persona = new.id_empleado into informacion_empleado;

        ----------------- BUSCA LOS DATOS DEL ESTUDIO -----------------
        select * from estudio e where e.id_estudio = new.id_estudio into informacion_estudio;

        ----------------- REALIZA EL NUEVO INSERT -----------------
        insert into estudios_x_empleados
        values (new.id_empleado, informacion_empleado.nombre, informacion_empleado.apellido, new.id_estudio,
                informacion_estudio.nombre, 1, new.fecha);
    end if;

    return new;
end;

$tr_alta_estudio_realizado$
    language plpgsql;

create or replace trigger tr_alta_estudio_realizado
    before insert
    on estudio_realizado
    for each row
execute procedure fn_alta_estudio_realizado();

-------------------------------------- PRUEBAS--------------------------------------
begin;

insert into estudio_realizado
values (1, 1, current_date, 1, 1, 'RESULTADO', 'OBSERVACIÓN', 12344.5);

select *
from estudios_x_empleados;

insert into estudio_realizado
values (3, 1, current_date, 1, 1, 'RESULTADO', 'OBSERVACIÓN', 12344.5);

select *
from estudios_x_empleados;

rollback;

-- b) Audite la tabla empleados solo cuando se modifique el campo sueldo por un sueldo mayor. Se debe guardar un
-- registro en la tabla audita_empleado. Los datos que debe almacenar la nueva tabla serán: id, usuario, la fecha
-- cuando se produjo la modificación, el id, nombre y apellido del empleado, el sueldo antes de la modificación y el
-- sueldo después de la modificación, además de un campo llamado porcentaje, que guardará el porcentaje de
-- aumento.
--  Nota2: porcentaje = ((sueldo_aumentado - sueldo_sin_aumento) / sueldo_sin_aumento) * 100

create or replace function fn_auditar_empleado() returns trigger
as
$tr_auditar_empleado$
declare
    informacion_empleado persona%rowtype;
    porcentaje_final     float;
begin

    create table if not exists audita_empleado
    (
        id                serial,
        usuario           varchar(100),
        fecha             date,
        id_empleado       int,
        nombre_empleado   varchar(150),
        apellido_empleado varchar(150),
        sueldo_anterior   numeric(9, 2),
        sueldo_nuevo      numeric(9, 2),
        porcentaje        float
    );

    porcentaje_final = ((new.sueldo - old.sueldo) / old.sueldo) * 100;

    select * from persona p where p.id_persona = new.id_empleado into informacion_empleado;

    insert into audita_empleado
    values (default, user, current_date, new.id_empleado, informacion_empleado.nombre, informacion_empleado.apellido,
            old.sueldo, new.sueldo, porcentaje_final);

    return new;
end;

$tr_auditar_empleado$
    language plpgsql;

create or replace trigger tr_auditar_empleado
    before update
        of sueldo
    on empleado
    for each row
    when ( new.sueldo > old.sueldo )
execute procedure fn_auditar_empleado();

-------------------------------------- PRUEBAS--------------------------------------
begin;

-- sueldo anterior: 1940000
update empleado e
set sueldo = 1940000
where id_empleado = 853;

select *
from audita_empleado;

rollback;