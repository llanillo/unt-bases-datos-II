--  Ejercicio nro. 1:
--
-- tareas:
-- a) Escriba un procedimiento almacenado (SP) para agregar registros a la tabla persona. Reciba
-- todos los parámetros necesarios excepto el id (max + 1) que se deberá obtener dentro del SP.
-- Muestre un mensaje de error si no se pudo realizar. Nombre sugerido: persona_alta.

create or replace procedure sp_persona_alta(nombre varchar(100), apellido varchar(100), dni varchar(8),
                                            fecha_nacimiento date,
                                            domicilio varchar(100),
                                            telefono varchar(15)) AS
$$
declare
    existe_dni bool;
begin
    if nombre is null or nombre = '' then
        raise exception 'El nombre es obligatorio';
    end if;

    if apellido is null or apellido = '' then
        raise exception 'El apellido es obligatorio';
    end if;

    if dni is null or dni = '' then
        raise exception 'El DNI es obligatorio';
    end if;

    if exists(select 1 from persona p where p.dni like $3) then
        raise exception 'Ya existe una persona con el DNI ingresado';
    end if;

    insert into persona values ((select max(id_persona) + 1 from persona), $1, $2, $3, $4, $5, $6);
    raise notice 'Se insertó la persona %, % de manera exitosa', $1, $2;
exception
    when others then
        raise exception 'Error en la inserción de la persona %', SQLERRM;
end;
$$ language plpgsql;

-- b) Escriba un SP para agregar registros en la tabla empleado, pase todos los campos por
-- parámetro, respecto a los campos que son FK pase el DNI de la persona, el nombre de la
-- especialidad y el nombre del cargo. Verifique que dichos datos existan para poder hacer el alt
-- Nombre sugerido: empleado_alta.

create or replace procedure sp_empleado_alta(p_dni varchar(8), p_especialidad varchar(100), p_cargo varchar(100),
                                             p_fecha_ingreso date, p_sueldo numeric(9, 2), p_fecha_baja date) as
$$
begin

    if not exists(select * from persona p where p.dni = p_dni) then
        raise exception 'No existe una persona con el dni ingresado';
    end if;

    if not exists(select * from especialidad where especialidad = p_especialidad) then
        raise exception 'No existe la especialidad ingresada';
    end if;

    if not exists(select * from cargo where cargo = p_cargo) then
        raise exception 'No existe el cargo ingresado';
    end if;

    if p_fecha_baja < p_fecha_ingreso then
        raise exception 'La fecha de baja no puede ser anterior a la fecha de ingreso';
    end if;

    insert into empleado
    values ((select id_persona from persona p where p.dni like $1),
            (select id_especialidad from especialidad e where e.especialidad like $2),
            (select cargo from cargo c where c.cargo like $3),
            (select current_date), $4, null);
    raise notice 'Se insertó el empleado de manera exitosa';
exception
    when others then
        raise exception 'Error en la inserción de la persona %', SQLERRM;
end ;
$$ language plpgsql;

-- c) Realice un SP que permita modificar el saldo de una factura. Debe recibir como parámetro el
-- id de la factura y el monto que se pagó que deberá ser descontado del saldo. Verifique que el
-- número de factura exista (de momento no es necesario ningún otro control). Nombre suerido:
-- factura_modifica_saldo.

create or replace procedure sp_factura_modifica_saldo(id_factura bigint, monto numeric(9, 2)) as
$$
declare
    existe_factura boolean;
    saldo_factura  numeric(10, 2);
begin
    select exists(select 1 from factura f where f.id_factura = $1) into existe_factura;

    if not existe_factura then
        raise exception 'No el número de factura ingresado';
    end if;

    if monto is null or monto < 0 then
        raise exception 'Se debe ingresar un monto positivo como pago';
    end if;

    select saldo from factura f where f.id_factura = $1 into saldo_factura;

    if monto > saldo_factura then
        raise exception 'No se puede realizar un pago mayor a lo adeudado';
    end if;

    update factura set saldo = saldo - $2 where id_factura = $1;
    raise notice 'Se modificó correctamente la factura';

exception
    when others then raise exception 'Error en la modificación del saldo de la factura %', SQLERRM;
end;
$$ language plpgsql;

-- d) Escriba un SP para modificar el precio de la tabla medicamento. La función debe recibir por
-- parámetro, el nombre de un laboratorio y el porcentaje de aumento. Verifique que el
-- laboratorio exista y modifique todos los medicamentos de ese laboratorio. Nombre sugerido:
-- medicamento_modifica_por_laboratorio.

create or replace procedure sp_medicamento_modifica_por_laboratorio(laboratorio varchar(50), porcentaje float) as
$$
declare
    existe_laboratorio bool;
begin
    select exists(select 1 from laboratorio l where l.laboratorio like $1) into existe_laboratorio;

    if not existe_laboratorio then
        raise exception 'No existe el laboratorio indicado';
    end if;

    if porcentaje is null or porcentaje < 0 then
        raise exception 'El porcentaje ingresado es inválido';
    end if;

    update medicamento
    set precio = precio * (1 + porcentaje / 100)
    where id_laboratorio = (select id_laboratorio from laboratorio l where laboratorio like $1);

    raise notice 'Se modificó exitosamente el precio del medicamento';

exception
    when others then raise exception 'Error en la modificación del precio de los medicamentos %', SQLERRM;
end ;
$$ language plpgsql;

-- e) Realice un SP para eliminar un medicamento según su nombre. Recuerde que puede estar
-- referenciado en otras tablas por lo que deberá hacer los
-- delete necesarios para poder eliminar el medicamento.Nombre sugerido: medicamento_eliminar

create or replace procedure sp_medicamento_eliminar(nombre_medicamento varchar(50))
as
$$
declare
    id_medicamento_borrar int;
    existe_medicamento    bool;
begin
    select exists(select id_medicamento from medicamento m where m.nombre like nombre_medicamento);

    if not existe_medicamento then
        raise exception 'No existe el medicamento ingresado';
    end if;

    select id_medicamento from medicamento m where m.nombre like nombre_medicamento into id_medicamento_borrar;

    update tratamiento set id_medicamento = null where id_medicamento = id_medicamento_borrar;
    delete from compra where id_medicamento = id_medicamento_borrar;
    delete from medicamento where id_medicamento = id_medicamento_borrar;

    raise notice 'Se elimino exitosamente el medicamento de la base de datos (Incluyendo todas sus referencias)';

exception
    when others then raise exception 'Error en el eliminado del medicamento %', SQLERRM;
end;
$$ language plpgsql;

-- Ejercicio nro.2:
-- Realice los siguientes procedimientos almacenados para que muestren la información solicitada.
-- a) Un SP que muestre el nombre y apellido de un paciente según un DNI ingresado.Nombre
-- sugerido: paciente_obtener.

create or replace procedure sp_paciente_obtener(dni_buscado varchar, out p_nombre varchar, out p_apellido varchar)
as
$$
begin
    select p.nombre, p.apellido from persona p where dni like $1 into p_nombre, p_apellido;

exception
    when others then raise exception 'Errors en la búsqueda del paciente %', SQLERRM;
end;
$$ language plpgsql;

call sp_paciente_obtener('37870755', null, null);

-- b) Un SP que muestre el precio y stock de un medicamente.Debe recibir como parámetro el
-- nombre del medicamento.Nombre sugerido: medicamento_precio_stock.

create or replace procedure sp_medicamento_precio_stock(nombre_medicamento varchar, out p_precio numeric(8, 2),
                                                        out p_stock int)
as
$$
begin
    select m.precio, m.stock from medicamento m where nombre like $1 into p_precio, p_stock;
exception
    when others then raise exception 'Error en la búsqueda del medicamento %', SQLERRM;
end;
$$ language plpgsql;

call sp_medicamento_precio_stock('PANADOL MASTICABLE NINOS', null, null);

-- c) Escriba un SP que muestre el total adeudado (campo saldo de las facturas) por un paciente,
-- según un número de DNI ingresado.Nombre sugerido: paciente_deuda.

create or replace procedure sp_paciente_deuda(dni varchar, out p_saldo numeric)
as
$$
declare
    existe_paciente bool;
begin
    select exists(select 1 from persona p where p.dni like $1) into existe_paciente;

    if not existe_paciente then
        raise exception 'No existe el usuario ingresado';
    end if;

    select sum(saldo)
    from persona p
             inner join paciente pa on p.id_persona = pa.id_paciente
             inner join factura f using (id_paciente)
    where p.dni like $1
    into p_saldo;

exception
    when others then raise exception 'Error en la búsqueda del total adeudado por el paciente %', SQLERRM;
end;
$$
    language plpgsql;

call sp_paciente_deuda('6284417', null);

-- d) Realice un SP que muestre la cantidad de veces que una cama estuvo en mantenimiento, se
-- debe mandar como parámetro el id de la cama. Nombre sugerido:
-- cama_cantidad_mantenimiento.

create or replace procedure sp_cama_cantidad_mantenimiento(id_cama bigint, out total_veces int)
as
$$
declare
    existe_cama bool;
begin
    select exists(select 1 from cama c where c.id_cama = $1) into existe_cama;

    if not existe_cama then
        raise exception 'No existe la cama ingresada';
    end if;

    select count(*)
    from cama c
             inner join mantenimiento_cama mc using (id_cama)
    where c.id_cama = $1
    into total_veces;

exception
    when others then raise exception 'Error en la búsqueda de la cama %', SQLERRM;
end;
$$
    language plpgsql;

call sp_cama_cantidad_mantenimiento(1, null);

-- Ejercicio nro. 3:
-- Realice los siguientes procedimientos almacenados utilizando cursores.
-- a) Realice un SP donde se listen todas las obras sociales con toda su información. Nombre
-- sugerido: obra_social_listado.

create or replace procedure sp_obra_social_listado()
as
$$
declare
    cursor_obras_sociales cursor for select *
                                     from obra_social;
    obras_sociales_fila obra_social%rowtype;
begin
    open cursor_obras_sociales;
    loop
        fetch cursor_obras_sociales into obras_sociales_fila;
        exit when not found;
        raise notice 'ID=%, Sigla=%, Nombre=%, Dirección=%, Localidad=%, Provincia=%, Teléfono=%',
            obras_sociales_fila.id_obra_social, obras_sociales_fila.sigla, obras_sociales_fila.nombre,
            obras_sociales_fila.direccion, obras_sociales_fila.localidad, obras_sociales_fila.provincia,
            obras_sociales_fila.telefono;
    end loop;

    close cursor_obras_sociales;
end;
$$
    language plpgsql;

call sp_obra_social_listado();

-- b) Realice un SP donde se listen todas las camas
-- cuyo estado sea “OK”. Nombre sugerido: cama_listado_ok

create or replace procedure sp_cama_listado_ok() as

$$
declare
    cursor_camas cursor for select *
                            from cama c
                            where c.estado like '%OK%';
    cama_fila cama%rowtype;
begin
    open cursor_camas;
    loop
        fetch cursor_camas into cama_fila;
        exit when not found;
        raise notice 'ID=%, Tipo=%, Estado=%', cama_fila.id_cama, cama_fila.tipo, cama_fila.estado;
    end loop;
    close cursor_camas;
end;
$$
    language plpgsql;

call sp_cama_listado_ok();

-- c) Realice un SP que liste todos los medicamentos cuyo stock sea
-- menor que 50. Nombre sugerido: medicamentos_poco_stock.

create or replace procedure sp_medicamentos_poco_stock()
as
$$
declare
    cursor_medicamento cursor for select *
                                  from medicamento m
                                  where m.stock < 50;
    medicamento_fila medicamento%rowtype;
begin
    open cursor_medicamento;
    loop
        fetch cursor_medicamento into medicamento_fila;
        exit when not found;
        raise notice 'ID=%, Nombre=%, PresentaciÓn=%, Precio=%, Stock=%', medicamento_fila.id_medicamento, medicamento_fila.nombre, medicamento_fila.presentacion, medicamento_fila.presentacion, medicamento_fila.stock;
    end loop;

    close cursor_medicamento;
end;
$$
    language plpgsql;

call sp_medicamentos_poco_stock();

-- d) Escriba un SP que muestre todas las consultas realizadas en determinada fecha (no haga
-- JOINS). Debe recibir por parámetro la fecha. Nombre sugerido: consulta_listado_por_fecha.

create or replace procedure sp_consulta_listado_por_fecha(fecha date)
as
$$
declare
    cursor_consulta cursor for select *
                               from consulta c
                               where c.fecha = $1;
    consulta_fila consulta%rowtype;
begin
    open cursor_consulta;
    loop
        fetch cursor_consulta into consulta_fila;
        exit when not found;
        raise notice 'ID Paciente=%, ID Empleado=%, Hora=%, Resultado=%',
            consulta_fila.id_paciente, consulta_fila.id_empleado, consulta_fila.hora, consulta_fila.resultado;
    end loop;

    close cursor_consulta;
end ;
$$ language plpgsql;

-- call sp_consulta_listado_por_fecha('2019-01-01');

-- e) Realice un SP que muestre el nombre y apellido de un paciente, la fecha y nombre de los
-- estudios que se realizó. Debe recibir como parámetro el DNI del paciente. Nombre sugerido:
-- estudio_por_paciente.

create or replace procedure sp_estudio_por_paciente(dni varchar)
as
$$
declare
    cursor_paciente_estudio cursor for select p.nombre, p.apellido, e.nombre, er.fecha
                                       from persona p
                                                inner join paciente pa on p.id_persona = pa.id_paciente
                                                inner join estudio_realizado er using (id_paciente)
                                                inner join estudio e using (id_estudio)
                                       where p.dni like $1;
    paciente_estudio_fila record;
begin
    open cursor_paciente_estudio;
    loop
        fetch cursor_paciente_estudio into paciente_estudio_fila;
        exit when not found;
        raise notice 'Nombre=%, Apellido=%, Fecha=%, Estudio=%',
            paciente_estudio_fila.nombre, paciente_estudio_fila.apellido,
            paciente_estudio_fila.fecha, paciente_estudio_fila.nombre;
    end loop;

    close cursor_paciente_estudio;
end;
$$ language plpgsql;

call sp_estudio_por_paciente('6171789');

-- call sp_estudio_por_paciente('17728326');

-- f) Realice un SP que muestre el nombre, apellido y teléfono de los empleados que trabajan en
-- un determinado turno. Debe recibir por parámetro el nombre del turno. Nombre sugerido:
-- empleado_por_turno.

create or replace procedure sp_empleado_por_turno(turno varchar)
as
$$
declare
    cursor_empleado_turno cursor for select p.*
                                     from persona p
                                              inner join empleado e on p.id_persona = e.id_empleado
                                              inner join trabajan using (id_empleado)
                                              inner join turno t using (id_turno)
                                     where t.turno like $1;
    empleado_turno persona%rowtype;
begin
    open cursor_empleado_turno;
    loop
        fetch cursor_empleado_turno into empleado_turno;
        exit when not found;
        raise notice 'Nombre=%, Apellido=%, Telefono=%', empleado_turno.nombre, empleado_turno.apellido, empleado_turno.telefono;
    end loop;

    close cursor_empleado_turno;
end;
$$ language plpgsql;

call sp_empleado_por_turno('full');

-- Ejercicio nro. 4:
-- También usando cursores, realice los siguientes procedimientos almacenados con consultas más
-- complejas.

-- a) Un SP con los datos de los medicamentos, de un determinado laboratorio y clasificación,
-- cuyo precio sea menor que el promedio de precios de todos los medicamentos de ese
-- laboratorio y clasificación. Debe recibir por parámetro el nombre del laboratorio y el
-- nombre de la clasificación. Nombre sugerido: medicamento_laboratorio_clasificacion.

create or replace procedure sp_medicamento_laboratorio_clasificacion(p_laboratorio varchar, p_clasificacion varchar) as
$$
declare
    cursor_medicamento cursor for select *
                                  from medicamento m
                                           inner join laboratorio l using (id_laboratorio)
                                           inner join clasificacion cla using (id_clasificacion)
                                  where l.laboratorio like $1
                                    and cla.clasificacion like $2
                                    and m.precio < (select avg(m.precio)
                                                    from medicamento m
                                                             inner join laboratorio l using (id_laboratorio)
                                                             inner join clasificacion c using (id_clasificacion)
                                                    where l.laboratorio like $1
                                                      and c.clasificacion like $2);
    medicamento medicamento%rowtype;
begin
    open cursor_medicamento;
    loop
        fetch cursor_medicamento into medicamento; exit when not found;
        raise notice 'Nombre=%, Presentación=%, Precio=%, Stock=%', medicamento.nombre, medicamento.presentacion, medicamento.precio, medicamento.stock;
    end loop;
    close cursor_medicamento;
end;
$$
    language plpgsql;

-- b) Un SP que muestre los datos de los 10 pacientes a los cuales más se le facturó (tome en
-- cuenta el monto de las facturas). Nombre sugerido: factura_top_ten.

create or replace procedure sp_factura_top_ten()
as
$$
declare
    cursor_paciente cursor for select p.*, sum(f.monto) as monto_total
                               from persona p
                                        inner join paciente pa on p.id_persona = pa.id_paciente
                                        inner join factura f using (id_paciente)
                               group by id_persona, nombre, apellido, dni, fecha_nacimiento, domicilio, telefono
                               order by monto_total desc
                               limit 10;
    persona persona%rowtype;
begin
    open cursor_paciente;
    loop
        fetch cursor_paciente into persona;
        exit when not found;
        raise notice 'Nombre=%, Apellido=%, DNI=%, FechaNacimiento=%, Domicilio=%',
            persona.nombre, persona.apellido, persona.dni, persona.fecha_nacimiento, persona.domicilio;
    end loop;
end;

$$
    language plpgsql;

call sp_factura_top_ten();
