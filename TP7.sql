-- Ejercicio nro. 1:
-- Para mejorar y automatizar el funcionamiento de la base de datos “Hospital” realice las siguientes
-- tareas:
-- a) Realice una función que permita modificar la fecha de ingreso o la fecha de baja de un
-- empleado. Debe recibir como parámetros el dni del empleado, el nombre del campo a
-- modificar (fecha_ingreso/fecha_baja) y el valor del nuevo campo. Recuerde controlar que el
-- empleado a modificar exista, de lo contrario debe enviar un mensaje de error. Agregue más
-- controles de ser necesario.

create or replace function fn_modificar_fecha_empleado(varchar(8), varchar(8), date) returns void
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
        where p.dni like dni_buscado into fecha_auxiliar;

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
        where p.dni like dni_buscado into fecha_auxiliar;

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
        where medicamento.id_laboratorio =
              (select id_laboratorio from laboratorio l where l.laboratorio like nombre_buscado limit 1);
    end if;

    if entidad = 'P' then
        select exists(select 1 from proveedor l where l.proveedor like entidad) into existe;

        if not existe then
            raise exception 'No existe el proveedor';
        end if;

        update medicamento
        set precio = precio * porcentaje_final
        from proveedor p
        where medicamento.id_medicamento in (select distinct id_medicamento
                                             from compra c
                                             where c.id_proveedor in (select id_proveedor
                                                                      from proveedor p
                                                                      where p.proveedor like nombre_buscado));
    end if;

    if entidad = 'M' then
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
create or replace function fn_abm_cargos(nombre varchar(50), tipo varchar(50)) returns void
as
$$
declare
    existe boolean;
begin
    if tipo like '%insert%' then
        insert into cargo values ((select max(id_cargo) + 1 from cargo), nombre);
    elseif tipo like '%delete%' then
        delete from cargo c where c.cargo like nombre;
    else
        select exists(select 1 from cargo c where c.cargo like nombre) into existe;

        if not existe then
            raise exception 'No existe el cargo que se debe modificar';
        end if;

        update cargo set cargo = tipo where cargo.cargo like nombre;

    end if;

end;

$$
    language plpgsql;

d) Realice UNA función que permite realizar alta en las tablas tipo_estudio, patología, clasificación
y especialidad. Debe recibir dos parámetros, el primero el nombre de la tabla en la cual se
quiere agregar la información y el segundo el valor del campo a agregar.

Ejercicio nro. 2:
Realice las siguientes funciones para agregar funcionalidad al sistema. Para realizar esta tarea se
recomienda usar los “tipos de datos” creados en el ejercicio 2 del TP5 o crear un tipo nuevo de ser
necesario.
a) Escriba una función que reciba el nombre de una obra social y devuelva un listado de todos
los pacientes que cuentan con la misma. El listado debe tener id, nombre y apellido del
paciente, nombre y sigla de la obra social.