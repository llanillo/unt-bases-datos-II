-- Ejercicio nro. 1:
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes
-- tareas:
-- a) Realice una función que permita modificar la fecha de ingreso o la fecha de baja de un
-- empleado. Debe recibir como parámetros el dni del empleado, el nombre del campo a
-- modificar (fecha_ingreso/fecha_baja) y el valor del nuevo campo. Recuerde controlar que el
-- empleado a modificar exista, de lo contrario debe enviar un mensaje de error. Agregue más
-- controles de ser necesario.

create or replace function fn_modificar_fecha_empleado(varchar, varchar, date) returns void
as
$$
declare
    dni_buscado alias for $1;
    campo alias for $2;
    nueva_fecha alias for $3;
    existe_persona boolean;
    fecha_auxiliar date;
begin
    select exists(select 1 from persona p where p.dni like dni_buscado) into existe_persona;

    if not existe_persona then
        raise exception 'No existe la persona';
    end if;

    if campo like 'fecha_ingreso' then
        select e.fecha_baja
        from persona p
                 inner join empleado e on p.id_persona = e.id_empleado
        where p.dni like dni_buscado
        into fecha_auxiliar;

        if fecha_auxiliar > nueva_fecha then
            raise exception 'Se quizó ingresar una fecha_ingreso mayor que la de baja';
        end if;

        update empleado
        set fecha_ingreso = nueva_fecha
        from persona p
        where p.dni like dni_buscado
          and id_empleado = p.id_persona;
    elseif campo like 'fecha_baja' then
        select e.fecha_ingreso
        from persona p
                 inner join empleado e on p.id_persona = e.id_empleado
        where p.dni like dni_buscado
        into fecha_auxiliar;

        if fecha_auxiliar < nueva_fecha then
            raise exception 'Se quizó ingresar una fecha_baja menor que la de ingreso';
        end if;

        update empleado set fecha_baja = nueva_fecha from persona p where p.dni like dni_buscado;
    else
        raise exception 'No se ingresó una fecha válida';
    end if;
end;

$$ language plpgsql;

-- PRUEBA FUNCIÓN
select fn_modificar_fecha_empleado('18354930', 'fecha_ingreso', '2023-05-13');

select *
from persona p
         inner join empleado e on p.id_persona = e.id_empleado
where p.dni = '18354930';
--
-- b) Realice una función para modificar el precio de un medicamento. La función debe recibir cuatro
-- parámetros, el primero indica si los precios se modifican por laboratorio, por proveedor o un
-- medicamento en particular (L/P/M), cualquier otra opción es inválida. El segundo argumento
-- indica el nombre del laboratorio, proveedor o medicamento (sin importar la presentación), el
-- tercero, si la modificación de los precios es un aumento o descuento (A/D) y el cuarto indicará
-- el porcentaje de aumento o descuento a modificar, éste va de 0.01 a 0.99, cualquier otro valor
-- es inválido. Realice todos los controles de existencia de los medicamentos, laboratorios y
-- proveedores, además, debe controlar que cada uno de los datos pasados a la función cumplan
-- con los requerimientos planteados, de lo contrario la función debe enviar un mensaje según el
-- error cometido.

create or replace function fn_modificar_precio_medicamento(char, varchar(50), char, numeric) returns void
as
$$
declare
    entidad alias for $1;
    nombre_buscado alias for $2;
    tipo alias for $3;
    porcentaje_a_modificar alias for $4;
    existe           boolean;
    porcentaje_final numeric;
begin
    if entidad not in ('L', 'P', 'M') then
        raise exception 'El primer argumento es inválido';
    end if;

    if nombre_buscado is null or nombre_buscado = '' then
        raise exception 'El segundo argumento es inválido';
    end if;

    if tipo not in ('A', 'D') then
        raise exception 'El tercer argumento es inválido';
    end if;

    if porcentaje_a_modificar < 0.01 or porcentaje_a_modificar > 0.99 then
        raise exception 'El cuarto argumento es inválido';
    end if;

    if tipo = 'A' then
        porcentaje_final = (1 + porcentaje_a_modificar);
    elseif tipo = 'D' then
        porcentaje_final = (1 - porcentaje_a_modificar);
    end if;

    if entidad = 'L' then
        select exists(select 1 from laboratorio l where l.laboratorio like nombre_buscado) into existe;

        if not existe then
            raise exception 'No existe el laboratorio';
        end if;

        update medicamento
        set precio = precio * porcentaje_final
        from laboratorio l
        where id_laboratorio =
              (select id_laboratorio from laboratorio l where l.laboratorio like nombre_buscado limit 1);

    elseif entidad = 'P' then
        select exists(select 1 from proveedor l where l.proveedor like entidad) into existe;

        if not existe then
            raise exception 'No existe el proveedor';
        end if;

        update medicamento
        set precio = precio * porcentaje_final
        from proveedor p
        where id_medicamento in (select distinct id_medicamento
                                 from compra c
                                 where c.id_proveedor in (select id_proveedor
                                                          from proveedor p
                                                          where p.proveedor like nombre_buscado));

    elseif entidad = 'M' then
        select exists(select 1 from medicamento m where m.nombre like nombre_buscado) into existe;

        if not existe then
            raise exception 'No existe el medicamento';
        end if;

        update medicamento
        set precio = precio * porcentaje_final
        where medicamento.nombre = nombre_buscado;
    end if;

end;

$$ language plpgsql;

-- c) Realice una función para el ABM (Alta-Baja-Modificación) de los cargos. Debe recibir dos
-- parámetros, el primero será el nombre del cargo y el segundo, en el caso de agregar o borrar
-- un registro, la palabra “insert” o “delete” respectivamente, o en caso de realizar una
-- modificación, debe ser el nuevo nombre del cargo que debe reemplazar al existente (el del
-- primer parámetro).

create or replace function fn_abm_cargos(nombre varchar, tipo varchar) returns void
as
$$
declare
    existe_cargo boolean;
begin
    if nombre is null or nombre = '' then
        raise exception 'El nombre es inválido';
    end if;

    if tipo is null or tipo = '' then
        raise exception 'El tipo es inválido';
    end if;

    select exists(select 1 from cargo c where c.cargo like nombre) into existe_cargo;

    if tipo like 'insert' then
        if existe_cargo then
            raise exception 'Se trató de insertar un cargo ya existente';
        end if;

        insert into cargo values ((select max(id_cargo) + 1 from cargo), nombre);
    elseif tipo like 'delete' then
        if not existe_cargo then
            raise exception 'Se trató de eliminar un cargo que no existe';
        end if;

        delete from cargo c where c.cargo like nombre;
    elseif tipo like 'update' then
        if not existe_cargo then
            raise exception 'Se trató de modificar un cargo que no existe';
        end if;

        update cargo set cargo = tipo where cargo.cargo like nombre;
    else
        raise exception 'Se ingresó una opción de ABM inválida';

    end if;

end;
$$
    language plpgsql;

-- d) Realice UNA función que permite realizar alta en las tablas tipo_estudio, patología, clasificación
-- y especialidad. Debe recibir dos parámetros, el primero el nombre de la tabla en la cual se
-- quiere agregar la información y el segundo el valor del campo a agregar.

create or replace function fn_alta_estudio_patologia_clasificacion_especialidad(tabla varchar, valor varchar) returns void
as
$$
begin

    if tabla is null or tabla = '' then
        raise exception 'Se ingresó un nombre de tabla inválido';
    end if;

    if valor is null or valor = '' then
        raise exception 'Se ingresó un valor de tabla inválido';
    end if;

    if tabla like 'tipo_estudio' then
        insert into tipo_estudio values ((select max(id_tipo) + 1 from tipo_estudio), valor);
    elseif tabla like 'patología' then
        insert into patologia values ((select max(id_patologia) + 1 from patologia), valor);
    elseif tabla like 'clasificacion' then
        insert into clasificacion values ((select max(id_clasificacion) + 1 from clasificacion), valor);
    else
        raise exception 'Se recibió un nombre de tabla inválido';
    end if;
end;
$$
    language plpgsql;

-- Ejercicio nro. 2:
-- Realice las siguientes funciones para agregar funcionalidad al sistema. Para realizar esta tarea se
-- recomienda usar los “tipos de datos” creados en el ejercicio 2 del TP5 o crear un tipo nuevo de ser
-- necesario.
-- a) Escriba una función que reciba el nombre de una obra social y devuelva un listado de todos
-- los pacientes que cuentan con la misma. El listado debe tener id, nombre y apellido del
-- paciente, nombre y sigla de la obra social.

drop type if exists tipo_obra_social_paciente;
create type tipo_obra_social_paciente as
(
    id_paciente        int,
    nombre_paciente    varchar,
    apellido_paciente  varchar,
    nombre_obra_social varchar,
    sigla_obra_social  varchar
);

create or replace function fn_listado_obra_social(obra_social_nombre varchar) returns setof tipo_obra_social_paciente
as
$$
declare
    fila_buscada       tipo_obra_social_paciente;
    existe_obra_social boolean;
begin

    if obra_social_nombre is null or obra_social_nombre = '' then
        raise exception 'El nombre de la obra social es inválido';
    end if;

    select exists(select 1 from obra_social ob where ob.nombre like obra_social_nombre) into existe_obra_social;

    if not existe_obra_social then
        raise exception 'No existe la obra social recibida';
    end if;

    for fila_buscada in select p.id_persona, p.nombre, p.apellido, ob.nombre, ob.sigla
                        from obra_social ob
                                 inner join paciente pa using (id_obra_social)
                                 inner join persona p on pa.id_paciente = p.id_persona
                        where ob.nombre like obra_social_nombre
        loop
            return next fila_buscada;
        end loop;
    return;
end;
$$
    language plpgsql;

select *
from fn_listado_obra_social('OBRA SOCIAL PARA LA ACTIVIDAD DOCENTE');

-- b) Escriba una función que reciba el nombre de un proveedor y entregue un listado con el
-- código, nombre, clasificación de los medicamentos, nombre del laboratorio que los
-- produce, nombre del proveedor y el precio que se pagó por dichos medicamentos.

drop type if exists clasificacion_medicamento_laboratorio_proveedor;
create type tipo_medicamento_laboratorio_proveedor as
(
    codigo_medicamento int,
    medicamento        varchar(50),
    clasificacion      varchar(75),
    laboratorio        varchar(50),
    proveedor          varchar(50),
    precio             numeric(8, 2)
);

drop function fn_listado_proveedor_medicamento_laboratorio(varchar(100));
create or replace function fn_listado_proveedor_medicamento_laboratorio(nombre_proveedor varchar(100)) returns setof tipo_medicamento_laboratorio_proveedor
as
$$
declare
    existe boolean;
begin
    if nombre_proveedor is null or nombre_proveedor = '' then
        raise exception 'El nombre del proveedor es inválido';
    end if;

    select exists(select 1 from proveedor p where p.proveedor like nombre_proveedor) into existe;

    if not existe then
        raise exception 'No existe el proveedor reibido';
    end if;

    return query select m.id_medicamento, m.nombre, c.clasificacion, l.laboratorio, p.proveedor, m.precio
                 from medicamento m
                          inner join clasificacion c using (id_clasificacion)
                          inner join laboratorio l using (id_laboratorio)
                          inner join compra co using (id_medicamento)
                          inner join proveedor p using (id_proveedor)
                 where p.proveedor like nombre_proveedor;
    return;
end;
$$
    language plpgsql;

select *
from proveedor;
select *
from fn_listado_proveedor_medicamento_laboratorio('QUIMICA SUIZA S.A.');

-- c) Escriba una función que reciba una fecha y devuelva el listado de todas las consultas
-- realizadas en esa fecha, además, debe mostrar el nombre y apellido del paciente, nombre y
-- apellido del médico, y el nombre del consultorio donde se realizaron las consultas.

drop type if exists tipo_paciente_medico_consultorio;
create type tipo_paciente_medico_consultorio as
(
    nombre_paciente   varchar(100),
    apellido_paciente varchar(100),
    nombre_medico     varchar(100),
    apellido_medico   varchar(100),
    consultorio       varchar(100)
);

create or replace function fn_listado_paciente_medico_consultorio(fecha_buscada date) returns setof tipo_paciente_medico_consultorio
as
$$
declare
begin

    if fecha_buscada > current_date then
        raise exception 'Se ingresó una fecha inválida';
    end if;

    return query select pa.nombre, pa.apellido, me.nombre, me.apellido, co.nombre
                 from consulta c
                          inner join consultorio co using (id_consultorio)
                          inner join paciente p using (id_paciente)
                          inner join persona pa on p.id_paciente = pa.id_persona
                          inner join empleado e using (id_empleado)
                          inner join persona me on me.id_persona = e.id_empleado
                 where c.fecha = fecha_buscada;
end;
$$
    language plpgsql;

select *
from fn_listado_paciente_medico_consultorio('2019-01-01');

-- d) Escriba una función que reciba el dni de un paciente y devuelva todas las internaciones que
-- tuvo (aquellas en las que ya fue dado de alta). Se debe mostrar nombre y apellido del
-- paciente, nombre y apellido del médico que ordenó la internación, fecha de alta y costo de
-- las mismas.

drop type if exists tipo_paciente_medico_internacion;
create type tipo_paciente_medico_internacion as
(
    nombre_paciente   varchar(100),
    apellido_paciente varchar(100),
    nombre_medico     varchar(100),
    apellido_medico   varchar(100),
    fecha_alta        date,
    costo             numeric(10, 2)
);

create or replace function fn_listado_internaciones_paciente_medico(dni_buscado varchar) returns setof tipo_paciente_medico_internacion
as
$$
declare
    existe boolean;
begin

    if dni_buscado is null or dni_buscado = '' then
        raise exception 'Se ingresó un DNI inválido';
    end if;

    select exists(select 1 from persona p where p.dni like dni_buscado) into existe;

    if not existe then
        raise exception 'No existe un paciente con el DNI recibido';
    end if;

    return query select pa.nombre, pa.apellido, me.nombre, me.apellido, i.fecha_alta, i.costo
                 from internacion i
                          inner join paciente p using (id_paciente)
                          inner join persona pa on p.id_paciente = pa.id_persona
                          inner join empleado e on i.ordena_internacion = e.id_empleado
                          inner join persona me on e.id_empleado = me.id_persona
                 where pa.dni like dni_buscado;
end;
$$
    language plpgsql;

select *
from fn_listado_internaciones_paciente_medico('10101457');

-- e) Escriba una función que reciba el nombre de un laboratorio y devuelva el código, nombre y
-- stock de todos los medicamentos de dicho laboratorio, además, debe mostrar la
-- clasificación de los mismos.

drop type if exists tipo_medicamento_laboratorio_clasificacion;
create type tipo_medicamento_laboratorio_clasificacion as
(
    id_medicamento     int,
    nombre_medicamento varchar(50),
    stock              int,
    clasificacion      varchar(75)
);

create or replace function fn_listado_medicamento_laboratorio_clasificacion(laboratorio_buscado varchar) returns setof tipo_medicamento_laboratorio_clasificacion
as
$$
declare
    existe_laboratorio boolean;
begin
    if laboratorio_buscado is null or laboratorio_buscado = '' then
        raise exception 'Se ingresó un laboratorio inválido';
    end if;

    select exists(select 1 from laboratorio l where l.laboratorio like laboratorio_buscado) into existe_laboratorio;

    if not existe_laboratorio then
        raise exception 'No existe el laboratorio recibido';
    end if;

    return query select m.id_medicamento, m.nombre, m.stock, c.clasificacion
                 from medicamento m
                          inner join clasificacion c using (id_clasificacion)
                          inner join laboratorio l using (id_laboratorio)
                 where l.laboratorio like laboratorio_buscado;
end;
$$
    language plpgsql;

select laboratorio
from laboratorio l;
select *
from fn_listado_medicamento_laboratorio_clasificacion('CARRION LABORATORIOS');

-- f) Escriba una función que reciba el dni de un paciente y muestre su nombre y apellido, y el
-- número, fecha y monto de todas las facturas que se le emitieron.

drop type if exists tipo_paciente_facturas;
create type tipo_paciente_facturas as
(
    dni_paciente      varchar(8),
    nombre_paciente   varchar(100),
    apellido_paciente varchar(100),
    id_factura        bigint,
    fecha             date,
    monto             numeric(10, 2)
);

create or replace function fn_paciente_facturas(dni_buscado varchar) returns setof tipo_paciente_facturas
as
$$
declare
    existe_paciente boolean;
begin
    if dni_buscado is null or dni_buscado = '' then
        raise exception 'Se ingresó un DNI inválido';
    end if;

    select exists(select 1
                  from paciente pa
                           inner join persona p on pa.id_paciente = p.id_persona
                  where p.dni like dni_buscado)
    into existe_paciente;

    if not existe_paciente then
        raise exception 'No existe un paciente con el DNI recibido';
    end if;

    return query select p.dni, p.nombre, p.apellido, f.id_factura, f.fecha, f.monto
                 from factura f
                          inner join paciente pa using (id_paciente)
                          inner join persona p on pa.id_paciente = p.id_persona
                 where p.dni like dni_buscado;
end;
$$
    language plpgsql;

select dni
from paciente pa
         inner join persona p on pa.id_paciente = p.id_persona;
select *
from fn_paciente_facturas('7374196');

-- g) Escriba una función que reciba el dni de un empleado y muestre su nombre y apellido,
-- nombre y marca de los equipos y la fecha de ingreso y estado de los mismos (equipos que
-- reparó dicho empleado).

create type tipo_empleado_equipos as
(
    nombre_empleado      varchar(100),
    apellido_empleado    varchar(100),
    nombre_equipo        varchar(100),
    marca_equipo         varchar(50),
    fecha_ingreso_equipo date,
    estado_equipo        varchar(25)
);

create or replace function fn_listado_empleado_equipos(dni_buscado varchar(8)) returns setof tipo_empleado_equipos
as
$$
declare
    fila_buscada tipo_empleado_equipos;
    existe       boolean;
begin
    select exists(select 1 from persona p where p.dni like dni_buscado) into existe;

    if not existe then
        raise exception 'No existe el empleado por el DNI recibido';
    end if;

    for fila_buscada in select p.nombre, p.apellido, e.nombre, e.marca, me.fecha_ingreso, me.estado
                        from equipo e
                                 inner join mantenimiento_equipo me using (id_equipo)
                                 inner join empleado em using (id_empleado)
                                 inner join persona p on em.id_empleado = p.id_persona
                        where p.dni like dni_buscado
        loop
            return next fila_buscada;
        end loop;
    return;
end;
$$
    language plpgsql;

select dni
from empleado em
         inner join persona p on em.id_empleado = p.id_persona
         inner join mantenimiento_equipo me using (id_empleado)
         inner join equipo eq using (id_equipo);

select *
from fn_listado_empleado_equipos('40201463');

-- h) Escriba una función que muestre el listado de las facturas indicando el número, fecha y
-- monto de las mismas, nombre y apellido del paciente, y una columna donde se indique un
-- mensaje en base al saldo pendiente. Si el saldo es menor que 500.000 en la columna se debe
-- mostrar “El cobro puede esperar”, si es mayor que 500.000 mostrar “Cobrar prioridad” y si
-- es mayor a 1.000.000 mostrar “Cobrar urgente”.

drop type if exists tipo_factura_paciente_saldo;
create type tipo_factura_paciente_saldo as
(
    id_factura        bigint,
    fecha_factura     date,
    monto             numeric(10, 2),
    nombre_paciente   varchar(100),
    apellido_paciente varchar(100),
    saldo_pendiente   varchar(250)
);

---------------------------------------- INICIO OPCIÓN 1 ----------------------------------------

create or replace function fn_mensaje_saldo_pendiente(saldo_pendiente numeric(10, 2)) returns varchar(250)
as
$$
declare
    salida varchar(250);
begin
    if saldo_pendiente <= 500000 then
        salida := 'El cobro puede esperar';
    elseif saldo_pendiente > 500000 then
        salida := 'Cobrar prioridad';
    elseif saldo_pendiente > 1000000 then
        salida := 'Cobrar urgente';
    else
        salida := 'Indefinido';
    end if;

    return salida;
end;
$$
    language plpgsql;

create or replace function fn_listado_saldo_facturas_paciente() returns setof tipo_factura_paciente_saldo
as
$$
declare
    fila_buscada tipo_factura_paciente_saldo;
begin
    for fila_buscada in select f.id_factura,
                               f.fecha,
                               f.monto,
                               p.nombre,
                               p.apellido,
                               fn_mensaje_saldo_pendiente(f.saldo) as deuda
                        from factura f
                                 inner join paciente pa using (id_paciente)
                                 inner join persona p on pa.id_paciente = p.id_persona
        loop
            return next fila_buscada;
        end loop;
    return;
end;
$$
    language plpgsql;

---------------------------------------- FIN OPCIÓN 1 ----------------------------------------

---------------------------------------- INICIO OPCIÓN 2 ----------------------------------------

create or replace function fn_listado_facturas_paciente2() returns setof tipo_factura_paciente_saldo
as
$$
declare

begin
    return query select f.id_factura,
                        f.fecha,
                        f.monto,
                        case
                            when f.saldo < 500000 THEN 'El cobro puede esperar'
                            when f.saldo > 100000 then 'Cobrar urgente'
                            else 'Cobrar prioridad'
                            end as deuda
                 from factura f
                          inner join paciente pa using (id_paciente);
end;
$$
    language plpgsql;

---------------------------------------- FIN OPCIÓN 2 ----------------------------------------

select *
from fn_listado_saldo_facturas_paciente();

-- i) Escriba UNA función que liste todos los registros de alguna de las siguientes tablas: cargo,
-- clasificaciones, especialidad, patología y tipo_estudio. No use estructuras de control para
-- decidir que tabla mostrar, solo debe averiguar si el parámetro pasado a la función coincide
-- con el nombre de alguna de las tablas requeridas.

---------------------------------------- INICIO OPCIÓN 1 ----------------------------------------

create or replace function fn_listado_multiples_tablas(nombre_tabla text) returns setof record
as
$$
begin
    if nombre_tabla is null or
       nombre_tabla not in ('cargo', 'clasificaciones', 'especialidad', 'patologia', 'tipo_estudio') then
        raise exception 'El nombre de tabla es inválido';
    end if;

    return query execute format('select * from %I', $1);
end;
$$ language plpgsql;

select *
from fn_listado_multiples_tablas('cargo') as (id_cargo integer, cargo varchar(50));

---------------------------------------- FIN OPCIÓN 1 ----------------------------------------

---------------------------------------- INICIO OPCIÓN 2 ----------------------------------------

drop type if exists tipo_tabla_sistema;
create type tipo_tabla_sistema as
(
    id    int,
    valor varchar
);

create or replace function fn_listado_multiples_tablas2(nombre_tabla varchar) returns setof tipo_tabla_sistema
as
$$
begin
    if nombre_tabla is null or
       nombre_tabla not in ('cargo', 'clasificaciones', 'especialidad', 'patologia', 'tipo_estudio') then
        raise exception 'El nombre de tabla es inválido';
    end if;

    return query execute format('select * from %I', $1);
end;
$$ language plpgsql;

select *
from fn_listado_multiples_tablas2('patologia');

---------------------------------------- FIN OPCIÓN 2 ----------------------------------------

-- Ejercicio nro. 3:
-- Plantee e implemente la o las funciones necesarias para realizar las siguientes tareas:

-- a) Cuando una cama entra en mantenimiento se agrega un registro en la tabla
-- mantenimiento_cama con datos en los campos obligatorios y en el campo estado.
-- Finalmente, cuando es arreglada se completa la fecha de egreso y quien fue el empleado
-- que la arregló, también se actualiza el campo estado de dicha tabla y el campo estado de la
-- tabla cama. Implemente la funcionalidad cuando una cama es arreglada (tenga en cuenta
-- que puede suceder que la cama no tenga arreglo y deba quedar fuera de servicio).

create or replace function fn_arreglar_cama(dni_empleado varchar, id_cama_arreglada smallint,
                                            nuevo_estado_cama varchar, p_fecha_egreso date) returns cama
as
$$
declare
    existe_cama          boolean;
    existe_empleado      boolean;
    salida               cama;
    id_empeado_reparador int;
begin
    ----------------------- INICIO CONTROLES -----------------------
    if nuevo_estado_cama is null or nuevo_estado_cama not in ('OK', 'EN REPARACION', 'FUERA DE SERVICIO') then
        raise exception 'El estado ingresado no es válido';
    end if;

    if p_fecha_egreso is null then
        raise exception 'La fecha ingresada no es válida';
    end if;

    if id_cama_arreglada is null then
        raise exception 'El id_cama no es válido';
    end if;

    select exists(select 1 from cama c where c.id_cama = id_cama_arreglada) into existe_cama;

    if not existe_cama then
        raise exception 'No existe una cama con el id recibido';
    end if;

    if dni_empleado is null or dni_empleado = '' then
        raise exception 'El dni ingresado no es válido';
    end if;

    select exists(select 1 from persona p where p.dni like dni_empleado) into existe_empleado;

    if not existe_empleado then
        raise exception 'No existe un empleado con el dni recibido';
    end if;
    ----------------------- FIN CONTROLES -----------------------

    select id_empleado
    from empleado em
             inner join persona p on em.id_empleado = p.id_persona
    where p.dni like dni_empleado
    into id_empeado_reparador;

    update mantenimiento_cama mc
    set fecha_egreso = p_fecha_egreso,
        id_empleado  = id_empeado_reparador,
        estado       = nuevo_estado_cama
    from cama c
    where c.id_cama = mc.id_cama;

    update cama c set estado = nuevo_estado_cama where c.id_cama = id_cama_arreglada returning * into salida;

    if nuevo_estado_cama = 'FUERA DE SERVICIO' then
        update internacion it set id_cama = null where it.id_cama = id_cama_arreglada;
    end if;

    return salida;
end;
$$
    language plpgsql;

select *
from fn_arreglar_cama('21936475', '90', 'OK');

select * from mantenimiento_cama mc
where mc.id_cama = '90';

-- b) Cuando se interna a un paciente se agregar un registro en la tabla internación solo con los
-- campos obligatorios, recién cuando se da de alta se completan los otros 3 campos de la
-- internación, además, se emite una factura por el monto de la internación. Implemente la
-- funcionalidad cuando se da de alta a un paciente.

-- TODO Esta malo porque el producto del costo con los días da un resultado grande y da desbordamiento la asignación con el campo costo de la tabla
create or replace function fn_alta_paciente(dni_paciente varchar(8)) returns factura
as
$$
declare
    existe           boolean;
    fecha_actual     date;
    hora_actual      time;
    fila_internacion record;
    costo_final      numeric(12, 2);
    dias_interado    int;
    salida           factura;
begin
    -- Comprueba que existe la persona
    select exists(select 1 from persona p where p.dni like dni_paciente) into existe;

    if not existe then
        raise exception 'No existe una persona con el DNI recibido';
    end if;

    -- Guarda la intrernación del paciente para calcular costo, días de internación, etc
    select *
    from internacion it
             inner join paciente pa using (id_paciente)
             inner join persona p on pa.id_paciente = p.id_persona
             inner join cama c using (id_cama)
             inner join habitacion h using (id_habitacion)
    into fila_internacion;

    hora_actual := current_time;
    fecha_actual := current_date;
    dias_interado := fecha_actual - fila_internacion.fecha_inicio;
    costo_final := fila_internacion.precio * dias_interado;

    -- Actualiza la internación
    update
        internacion it
    set fecha_alta = fecha_actual,
        hora       = hora_actual,
        costo      = costo_final::numeric(10, 2) -- TODO El enuncia no explica como calcular el costo
    from paciente pa
             inner join persona p on pa.id_paciente = p.id_persona
    where p.dni like dni_paciente
      and it.id_paciente = pa.id_paciente;

    -- Crea la nueva factura
    insert into factura
    values ((select max(id_factura) + 1 from factura),
            (select p.id_persona from persona p where p.dni like dni_paciente), fecha_actual, hora_actual, costo_final,
            'N', 0)
    into salida;

    return salida;
end;
$$
    language plpgsql;

select dni
from paciente pa
         inner join persona p on pa.id_paciente = p.id_persona;

insert into internacion
values ((select id_persona from persona p where p.dni like '37870755'),
        (select id_cama from cama c where c.estado like '%OK%' limit 1), current_date, 131);

select *
from internacion it
         inner join paciente pa using (id_paciente)
         inner join persona p on pa.id_paciente = p.id_persona
where p.dni like '37870755';

select *
from fn_alta_paciente('37870755');

select *
from factura f
         inner join paciente pa using (id_paciente)
         inner join persona p on pa.id_paciente = p.id_persona
where p.dni like '37870755';

-- c) No todas las consultas médicas tienen un diagnóstico porque a veces se espera el resultado
-- de algún estudio para dar con el mismo. Pero cuando se llega a un diagnóstico se indica un
-- tratamiento. Implemente la funcionalidad para asignar un diagnóstico e indicar un
-- tratamiento.

select *
from diagnostico;
select *
from patologia;
select *
from consulta;
select *
from tratamiento;