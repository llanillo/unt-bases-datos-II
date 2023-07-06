-- EJERCICIO N° 1: Funciones
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes tareas:
-- Se aconseja usar los tipos de datos (text, integer, numeric, date) para evitar problemas
-- de ejecución en las funciones.


-- a) Escriba una función para realizar altas en las tablas factura o bien, en la tabla pago, según corresponda.
-- Los parámetros que recibe la función son el nombre y apellido de un paciente, la fecha y el monto.
-- Si no existe  en la tabla factura un registro con el paciente y la fecha ingresada,
--  deberá realizar un nuevo ingreso en la tabla factura
-- Por el contrario si existe en la tabla factura un registro con el paciente y la fecha ingresada,
-- debe hacer un alta en la tabla pago con el id_factura correspondiente.  La fecha para el alta en la tabla pago no debe ser la pasada como parámetro, sino la del sistema.
-- Tenga en cuenta que puede existir un registro en la tabla pago con el id_factura, porque se realizan
-- pagos parciales. En ese caso debe actualizar el monto de la tabla pago sumándole al monto existente
-- el monto nuevo.
-- Recuerde realizar todos los controles a los parámetros.

create or replace function fn_alta_factura_pago(p_nombre varchar, p_apellido varchar, p_fecha date, p_monto numeric) returns void
as
$$
declare
    existe_paciente      boolean;
    existe_factura       boolean;
    existe_pago          boolean;
    paciente_con_factura record;
begin
    ---------------------- INICIO CONTROLES ----------------------
    if p_nombre is null or p_nombre = '' then
        raise exception 'El nombre ingresado es inválido';
    end if;

    if p_apellido is null or p_apellido = '' then
        raise exception 'El apellido ingresado es inválido';
    end if;

    if p_fecha is null then
        raise exception 'La fecha ingresada es inválido';
    end if;

    if p_monto is null then
        raise exception 'El monto ingresada es inválido';
    end if;

    select exists(select *
                  from persona p
                  where p.nombre like p_nombre
                    and p.apellido like p_apellido)
    into existe_paciente;

    if not existe_paciente then
        raise exception 'No existe una persona con esa información';
    end if;
    ---------------------- FIN CONTROLES ----------------------

    select exists(select *
                  from factura f
                           inner join paciente pa using (id_paciente)
                           inner join persona per on pa.id_paciente = per.id_persona
                  where per.nombre like p_nombre
                    and per.apellido like p_apellido
                  into paciente_con_factura)
    into existe_factura;

    if existe_factura then
        select exists(select 1 from pago p where p.id_factura = paciente_con_factura.id_factura) into existe_pago;

        if existe_pago then
            update pago p
            set monto = p_monto and fecha = current_time
            where id_factura = paciente_con_factura.id_factura;
        else
            insert into pago values (paciente_con_factura.id_factura, current_time, p_monto);
        end if;
    else
        insert into factura
        values ((select max(id_factura) + 1 from factura), paciente_con_factura.id_persona, p_fecha, current_time,
                p_monto,
                'F', null);
    end if;


end;
$$
    language plpgsql;

-- b) Escriba una función para listar los registros de la tabla empleado. La función recibirá
-- dos parámetros, nombre de una tabla (cargo o especialidad) y el nombre del cargo
-- o especialidad, según corresponda. La función deberá mostrar un listado de todos los empleados
-- que pertenecen a dicho cargo o especialidad. El listado debe tener el id, nombre, apellido, dni,
-- fecha de ingreso y sueldo del empleado, además del id y nombre del cargo o especialidad,
-- según corresponda. Recuerde realizar todos los controles a los parámetros.

create type tipo_listar_empleados as
(
    id_empleado            int,
    nombre_empleado        varchar,
    apellido_empleado      varchar,
    dni_empleado           varchar,
    fecha_ingreso_empleado date,
    sueldo_empleado        numeric,
    id_cargo_empleado      int,
    cargo_empleado         varchar
);

create or replace function fn_listar_empleados(p_nombre_tabla varchar, p_valor_tabla varchar) returns setof tipo_listar_empleados
as
$$
declare
begin

    if p_nombre_tabla is null or p_nombre_tabla not in ('cargo', 'especialidad') then
        raise exception 'El nombre de la tabla no es válido';
    end if;

    if p_valor_tabla is null or p_valor_tabla = '' then
        raise exception 'El valor de la tabla no es válido';
    end if;

    if p_nombre_tabla = 'cargo' then
        return query select p.id_persona,
                            p.nombre,
                            p.apellido,
                            p.dni,
                            em.fecha_ingreso,
                            em.sueldo,
                            c.id_cargo,
                            c.cargo
                     from cargo c
                              inner join empleado em using (id_cargo)
                              inner join persona p on em.id_empleado = p.id_persona
                     where c.cargo like p_valor_tabla;

    else
        return query select p.id_persona,
                            p.nombre,
                            p.apellido,
                            p.dni,
                            em.fecha_ingreso,
                            em.sueldo,
                            e.id_especialidad,
                            e.especialidad
                     from especialidad e
                              inner join empleado em using (id_especialidad)
                              inner join persona p on em.id_empleado = p.id_persona
                     where e.especialidad like p_valor_tabla;
    end if;
exception
    when others then raise exception 'Ocurrió un error al ejecutar la consulta %', SQLERRM;
end;

$$
    language plpgsql;

select *
from cargo;

select *
from fn_listar_empleados('cargo', 'DIRECTOR');

-- c) Escriba una función que reciba como parámetros el nombre y apellido de un empleado y
-- un porcentaje de modificación de sueldo (integer). Si el porcentaje ingresado es positivo,
-- debe aumentar el sueldo, por lo contrario, si el valor es negativo debe realizar un descuento.
-- En caso de ser 0, se debe modificar el sueldo, en un 5%, de todos los empleados que
-- tengan el mismo cargo del empleado pasado por parámetro. La función debe devolver un listado
-- con el id, nombre apellido, sueldo y, nombre del cargo. Recuerde realizar todos los controles
-- a los parámetros.

create or replace function fn_modificar_sueldo_empleado(p_nombre varchar, p_apellido varchar, p_porcentaje float) returns record
as
$$
declare
    cargo_empleado  varchar;
    existe_empleado boolean;
begin
    ----------------------------------- INICIO CONTROLES -----------------------------------
    if p_nombre is null or p_nombre = '' then
        raise exception 'El nombre ingresado no es válido';
    end if;

    if p_apellido is null or p_apellido = '' then
        raise exception 'El apellido ingresado no es válido';
    end if;

    select exists(select 1 from persona p where p.nombre like p_nombre and p.apellido like p_apellido)
    into existe_empleado;

    if not existe_empleado then
        raise exception 'No existe una persona con esos datos';
    end if;
    ----------------------------------- FIN CONTROLES -----------------------------------

    if p_porcentaje > 0 then
        update empleado e
        set sueldo = sueldo * (1 + p_porcentaje / 100)
        from persona p
        where p.nombre like p_nombre
          and p.apellido like p_apellido
          and p.id_persona = e.id_empleado;
    elseif p_porcentaje < 0 then
        update empleado e
        set sueldo = sueldo * (1 - p_porcentaje / 100)
        from persona p
        where p.nombre like p_nombre
          and p.apellido like p_apellido
          and p.id_persona = e.id_empleado;
    else

        select c.cargo
        from empleado e
                 inner join cargo c using (id_cargo)
        into cargo_empleado;

        update empleado e
        set sueldo = sueldo * 0.95
        from cargo c
        where c.id_cargo in (select id_cargo from cargo where cargo.cargo = cargo_empleado);
    end if;

    return query select p.id_persona, p.nombre, p.apellido, em.sueldo, c.cargo
                 from persona p
                          inner join empleado em on p.id_persona = em.id_empleado
                          inner join cargo c using (id_cargo);
end;
$$
    language plpgsql;

-- EJERCICIO N° 2: TRIGGERS
-- Realice los siguientes triggers, analizando cuidadosamente qué acción (INSERT, UPDATE o DELETE),
-- sobre qué tabla y cuándo (BEFORE o AFTER) se deben activar los mismos:

-- a) Cada vez que se realice un alta o una modificación (solo en el campo monto) en la tabla pago,
-- se deben modificar los campos, saldo y pagada de la tabla factura. Si el monto del pago es
-- igual al saldo de la factura, el campo pagada= ‘S’ y el campo saldo = 0, de lo contrario el campo pagada
-- = ‘N’ y el campo saldo= monto de la tabla factura menos el monto de la tabla pago.

create or replace function fn_alta_modificado_monto_pago() returns trigger
as
$tr_alta_modificado_monto_pago$
declare
    factura_pagada factura%rowtype;
begin

    select * from factura f where f.id_factura = new.id_factura into factura_pagada;

    if new.monto = factura_pagada.saldo then
        update factura f set saldo = 0, pagada = 'S' where f.id_factura = new.id_factura;
    else
        update factura f set saldo = new.monto, pagada = 'N' where f.id_factura = new.id_factura;
    end if;

    return new;
end;

$tr_alta_modificado_monto_pago$
    language plpgsql;

create or replace trigger tr_alta_modificado_monto_pago
    before insert or update of monto
    on pago
    for each row
    when (monto > 0)
execute procedure fn_alta_modificado_monto_pago();

-- b) Cuando se elimine un registro de la tabla laboratorios o clasificaciones, debe modificar todos
-- los registros de la tabla medicamento que hagan referencia al registro borrado.
-- Si se borra un laboratorio, debe modificar el laboratorio de los medicamentos
-- con “LABOSINRATO” (nombre de un laboratorio existente), por lo contrario, si lo
-- que se elimina es una clasificación, debe modificar con “INSECTICIDAS”. Además de
-- guardar todos los registros de la tabla medicamentos antes de ser modificados en otra
-- tabla llamada medi_modificado, la cual tendrá todos los campos de la tabla medicamentos,
-- además del nombre de la tabla que activó el trigger. Debe escribir una sola función.

create or replace function fn_eliminado_laboratorio_clasificacion() returns trigger
as
$tr_eliminado_laboratorio_clasificacion$
declare
    medicamento_modificado medicamento%rowtype;
begin
    create table if not exists medi_modificado
    (
        id_medicamento   integer,
        id_clasificacion smallint,
        id_laboratorio   smallint,
        nombre           varchar(50),
        presentacion     varchar(50),
        precio           numeric(8, 2),
        stock            integer
    );

    if tg_table_name not in ('laboratorio', 'clasificacion') then
        raise exception 'Trigger ejecutado en tabla inválida'
    end if;


    if tg_table_name = 'laboratorio' then

        for medicamento_modificado in select *
                                      from medicamento me
                                      where me.id_laboratorio = (select l.id_laboratorio
                                                                 from laboratorio l
                                                                 where l.laboratorio = old.laboratorio)
            loop
                insert into medi_modificado
                values (medicamento_modificado.id_medicamento, medicamento_modificado.id_clasificacion,
                        medicamento_modificado.id_laboratorio, medicamento_modificado.nombre,
                        medicamento_modificado.presentacion, medicamento_modificado.precio,
                        medicamento_modificado.stock);
            end loop;

        update medicamento m
        set id_laboratorio = (select id_laboratorio
                              from laboratorio l
                              where l.laboratorio like '%LABOSINRATO%'
                              limit 1)
        where m.id_laboratorio = old.id_laboratorio;
    elseif tg_table_name = 'clasificacion' then

        for medicamento_modificado in select *
                                      from medicamento me
                                      where me.id_clasificacion = (select c.id_clasificacion
                                                                   from clasificacion c
                                                                   where c.clasificacion = old.clasificacion)
            loop
                insert into medi_modificado
                values (medicamento_modificado.id_medicamento, medicamento_modificado.id_clasificacion,
                        medicamento_modificado.id_laboratorio, medicamento_modificado.nombre,
                        medicamento_modificado.presentacion, medicamento_modificado.precio,
                        medicamento_modificado.stock);
            end loop;


        update medicamento m
        set id_clasificacion = (select id_clasificacion
                                from clasificacion c
                                where c.clasificacion like '%INSECTICIDAS%'
                                limit 1)
        where m.id_laboratorio = old.id_laboratorio;
    end if;

    return old;
end;

$tr_eliminado_laboratorio_clasificacion$
    language plpgsql;


create or replace trigger tr_eliminado_laboratorio_clasificacion
    before delete
    on laboratorio
    for each row
execute procedure fn_eliminado_laboratorio_clasificacion();