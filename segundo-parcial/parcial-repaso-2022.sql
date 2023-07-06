-- EJERCICIO N° 1: Funciones
--
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes tareas:
--
-- a) Escriba una función que reciba como parámetros el nombre y apellido de un paciente, id_cama y
-- una fecha. Si existe un registro con el paciente y la cama ingresada, y no hay datos de la fecha_alta,
-- deberá modificar la fecha de alta con el valor ingresado. Por el contrario, si fecha_alta tiene dato almacenado,
-- deberá realizar un nuevo ingreso usando la fecha (recibida como parámetro) como fecha_inicio.
-- Realice todos los controles, y tenga en cuenta que hay camas que están fuera de servicio.

create or replace function fn_modificar_paciente_cama(p_nombre varchar, p_apellido varchar, p_id_cama int, p_fecha date) returns void
as
$$
declare
    existe_paciente       boolean;
    existe_cama           boolean;
    existe_internacion    boolean;
    id_paciente_internado int;
    internacion_buscada   internacion;
begin

    -- INICIO CONTROLES
    if p_nombre is null or p_nombre = '' then
        raise exception 'Se ingresó un nombre inválido';
    end if;

    if p_apellido is null or p_apellido = '' then
        raise exception 'Se ingresó un apellido inválido';
    end if;

    select exists(select p.id_persona
                  from persona p
                  where p.nombre like p_nombre
                    and p.apellido like p_apellido
                  into id_paciente_internado)
    into existe_paciente;

    select exists(select 1 from cama c where c.id_cama = p_id_cama) into existe_cama;

    if not existe_paciente then
        raise exception 'No existe la persona que se desea buscar';
    end if;

    if not existe_cama then
        raise exception 'No existe la cama que se desea buscar';
    end if;

    if p_fecha > current_date then
        raise exception 'La fecha ingresada es inválida';
    end if;

    select exists(select *
                  from internacion i
                  where i.id_paciente = id_paciente_internado
                    and i.id_cama
                  into internacion_buscada)
    into existe_internacion;

    if not existe_internacion then
        raise exception 'No existe la internación';
    end if;

    -- FIN CONTROLES

    if internacion_buscada.fecha_alta is null then
        update internacion i set fecha_alta = p_fecha where id_cama = p_id_cama and id_paciente = id_paciente_internado;
    else

    end if;

end;
$$
    language plpgsql;

-- b) Escriba una función para listar los registros de las tablas clasificaciones o laboratorio.
-- La función recibirá el nombre de la tabla y el nombre de la clasificación o laboratorio, según corresponda.
-- La función deberá mostrar un listado de todos los medicamentos que pertenecen a dicha clasificación o laboratorio.
-- El listado debe tener el id, nombre, presentación y precio del medicamento, además de id
-- y nombre del laboratorio o clasificación, según corresponda.

create type lista_clasificacion_laboratorio as
(
    id_medicamento           integer,
    nombre_medicamento       varchar,
    presentacion_medicamento varchar,
    precio_medicamento       numeric,
    id_tabla                 smallint,
    valor_tabla              varchar
);

create or replace function fn_listar_clasificaciones_laboratorio(p_nombre_tabla varchar, p_nombre_campo varchar) returns setof lista_clasificacion_laboratorio
as
$$
begin
    if p_nombre_campo is null or p_nombre_campo = '' then
        raise exception 'Se ingresó un nombre de campo inválido';
    end if;

    if p_nombre_tabla like 'clasificacion' then
        return query select m.id_medicamento, m.nombre, m.presentacion, m.precio, c.id_clasificacion, c.clasificacion
                     from clasificacion c
                              inner join medicamento m using (id_clasificacion)
                     where c.clasificacion like p_nombre_campo;
    elseif p_nombre_tabla like 'laboratorio' then
        return query select m.id_medicamento, m.nombre, m.presentacion, m.precio, l.id_laboratorio, l.laboratorio
                     from laboratorio l
                              inner join medicamento m using (id_laboratorio)
                     where l.laboratorio like p_nombre_campo;
    else
        raise exception 'El nombre de tabla es inválido';
    end if;
end;
$$ language plpgsql;

select *
from clasificacion;

select *
from fn_listar_clasificaciones_laboratorio('clasificacion', 'ANALGESICO RELAJANTE MUSCULAR');

-- c) Escriba una función que reciba como parámetros el nombre y presentación de un medicamento y un
-- porcentaje de modificación de precio. Si el porcentaje ingresado es positivo, debe aumentar
-- el precio, por lo contrario, si el valor es negativo debe realizar un descuento. En caso de ser 0,
-- se debe modificar el precio, en un 15%, de todos los medicamentos que sean producidos por el mismo
-- laboratorio que el medicamento ingresado como parámetro.  La función debe devolver un listado con el
-- id, nombre presentación, precio y nombre del laboratorio que lo produce.

create or replace function fn_modificar_precio_medicamento(p_nombre varchar, p_presentacion varchar, porcentaje float) returns setof record
as
$$
declare
    existe_medicamento   boolean;
    laboratorio_auxiliar varchar;
begin
    if p_nombre is null or p_nombre = '' then
        raise exception 'Se ingresó un nombre de medicamento inválido';
    end if;

    if p_presentacion is null or p_nombre = '' then
        raise exception 'Se ingresó una presentación de medicamento inválida';
    end if;

    select exists(select 1 from medicamento m where m.nombre like p_nombre and m.presentacion like p_presentacion)
    into existe_medicamento;

    if not existe_medicamento then
        raise exception 'No existe el medicamento ingresado';
    end if;

    if porcentaje > 0 then
        update medicamento m
        set precio = precio * (1 + porcentaje / 100)
        where m.nombre like p_nombre
          and m.presentacion like p_presentacion;

    elseif porcentaje < 0 then
        update medicamento m
        set precio = precio * (1 - porcentaje / 100)
        where m.nombre like p_nombre
          and m.presentacion like p_presentacion;
    else
        select l.laboratorio
        from laboratorio l
                 inner join medicamento m using (id_laboratorio)
        where m.nombre like p_nombre
          and m.presentacion like p_presentacion
        into laboratorio_auxiliar;

        update medicamento m
        set precio = precio * (1 - porcentaje / 100)
        from laboratorio l
        where m.nombre like p_nombre
          and m.presentacion like p_presentacion
          and l.id_laboratorio = m.id_laboratorio
          and l.laboratorio like laboratorio_auxiliar;
    end if;

    return query select m.id_medicamento, m.nombre, m.presentacion, m.precio, l.laboratorio
                 from medicamento m
                          inner join laboratorio l using (id_laboratorio)
                 where m.nombre like p_nombre
                   and m.presentacion like p_presentacion;
end;
$$
    language plpgsql;

-- EJERCICIO N° 2: TRIGGERS
--
-- Realice los siguientes triggers, analizando cuidadosamente qué acción (INSERT, UPDATE o DELETE),
-- sobre qué tabla y cuándo (BEFORE o AFTER) se deben activar los mismos:

-- a) Cada vez que se modifique la tabla internación, sólo si se modifica la fecha de alta,
-- debe calcular el campo costo como la cantidad de días por el costo de la habitación.
-- Se recomienda usar “EXTRACT(DAY FROM age(date(fecha_b),date(fecha_a))” para calcular la
-- cantidad de días de internación. Debe enviar un mensaje con el nombre del paciente,
-- la cantidad de días que estuvo internado y el costo de dicha internación.

create or replace function fn_costo_internacion_paciente() returns trigger
as
$tr_costo_internacion$
declare
    paciente_internado        persona;
    costo_final               numeric;
    costo_habitacion          numeric;
    cantidad_dias_internacion int;
begin
    select pe.*
    from persona pe
             inner join paciente p on pe.id_persona = p.id_paciente
             inner join internacion i using (id_paciente)
    where i.id_paciente = new.id_paciente
      and i.id_cama = new.id_cama
      and i.fecha_inicio = new.fecha_inicio
    into paciente_internado;

    select h.precio
    from habitacion h
             inner join cama c using (id_habitacion)
             inner join internacion i using (id_cama)
    where i.id_cama = new.id_cama
      and i.id_paciente = new.id_paciente
      and i.fecha_inicio = new.fecha_inicio
    into costo_habitacion;

    cantidad_dias_internacion := extract(day from age(date(new.fecha_inicio), date(new.fecha_alta)));
    costo_final := cantidad_dias_internacion * costo_habitacion;

    update internacion i
    set costo = costo_final
    where i.id_cama = new.id_cama
      and i.id_paciente = new.id_paciente
      and i.fecha_inicio = new.fecha_inicio;

    raise notice 'Id=%, Nombre=%, Cantidad días internado=%, Costo Internación=%',
        paciente_internado.id_persona, paciente_internado.nombre, cantidad_dias_internacion, costo_final;

    return new;
end;
$tr_costo_internacion$
    language plpgsql;

create or replace trigger tr_costo_internacion_paciente
    before update of fecha_alta
    on internacion
    for each row
execute procedure fn_costo_internacion_paciente();

-- b) Cuando se elimine una especialidad o un cargo, debe modificar todos los registros de la tabla
-- empleado que hagan referencia al registro borrado. Si se borra un cargo, debe modificar el cargo
-- del empleado con “SIN CARGO ASIGNADO”, por lo contrario, si lo que se elimina es una función, debe
-- modificar con “SIN ESPECIALIDAD MEDICA”. Además de guardar todos los registros modificados en otra tabla
-- llamada empleado_modi, la cual tendrá todos los campos de la tabla empleado. Debe escribir una sola función.

create or replace function fn_eliminar_cargo_especialidad() returns trigger
as
$tr_eliminar_cargo_especialidad$
declare
    existe_cargo        boolean;
    existe_especialidad boolean;
    empleado_auxiliar   empleado%rowtype;
begin
    create table if not exists empleado_modi
    (
        id_empleado     integer,
        id_especialidad integer,
        id_cargo        integer,
        fecha_ingreso   date,
        sueldo          numeric(9, 2),
        fecha_baja      date
    );

    select exists(select 1 from cargo c where c.cargo like 'SIN CARGO ASIGNADO') into existe_cargo;
    select exists(select 1 from especialidad e where e.especialidad like 'SIN ESPECIALIDAD MEDICA')
    into existe_especialidad;

    if not existe_especialidad then
        insert into especialidad values ((select max(id_especialidad) + 1), 'SIN ESPECIALIDAD MEDICA');
    end if;

    if not existe_cargo then
        insert into cargo values ((select max(id_cargo) + 1), 'SIN CARGO ASIGNADO');
    end if;

    if tg_table_name like 'cargo' then
        for empleado_auxiliar in select * from empleado e where e.id_cargo = old.id_cargo
            loop
                insert into empleado_modi
                values (empleado_auxiliar.id_empleado, empleado_auxiliar.id_especialidad, empleado_auxiliar.id_cargo,
                        empleado_auxiliar.fecha_ingreso, empleado_auxiliar.sueldo, empleado_auxiliar.fecha_baja);
            end loop;

        update empleado e
        set id_cargo = (select id_cargo from cargo c where c.cargo like 'SIN CARGO ASIGNADO')
        where e.id_cargo = old.id_cargo;
    elseif tg_table_name like 'especialidad' then

        for empleado_auxiliar in select * from empleado e where e.id_especialidad = old.id_especialidad
            loop
                insert into empleado_modi
                values (empleado_auxiliar.id_empleado, empleado_auxiliar.id_especialidad, empleado_auxiliar.id_cargo,
                        empleado_auxiliar.fecha_ingreso, empleado_auxiliar.sueldo, empleado_auxiliar.fecha_baja);
            end loop;

        update empleado e
        set id_especialidad = (select id_especialidad
                               from especialidad e
                               where e.especialidad like 'SIN ESPECIALIDAD MEDICA')
        where e.id_especialidad = old.id_especialidad;

    else
        raise exception 'Tabla inválida';
    end if;

    return old;
end;
$tr_eliminar_cargo_especialidad$
    language plpgsql;

create or replace trigger tr_eliminar_cargo
    before delete
    on cargo
    for each row
execute procedure fn_eliminar_cargo_especialidad();

create or replace trigger tr_eliminar_especialidad
    before delete
    on especialidad
    for each row
execute procedure fn_eliminar_cargo_especialidad();