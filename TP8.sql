-- Ejercicio nro. 1:
-- Realice las siguientes modificaciones en las tablas indicadas:

-- ● Modifique el tipo de dato del campo dosis (character varying) de la tabla Tratamiento por el tipo
-- integer.
begin;
alter table tratamiento
    alter column dosis type integer using dosis::integer;
commit;

-- ALTER TABLE tratamiento ALTER COLUMN dosis SET DATA TYPE integer USING dosis::integer;

-- ● Realice una función que modifique el campo saldo de la tabla factura, el mismo debe ser la
-- diferencia entre el monto de la factura y los pagos realizados para dicha factura.
create or replace function fn_modificar_saldo() returns trigger
as
$$
declare
begin
    update factura f
    set saldo = abs((select sum(p.monto)
                     from pago p
                              inner join factura on f.id_factura = p.id_factura) - f.saldo);
end
$$
    language plpgsql;

-- Ejercicio nro. 2:
-- Realice los siguientes triggers analizando con qué acción (INSERT, UPDATE o DELETE), sobre cual tabla y
-- en qué momento (BEFORE o AFTER) se deben disparar los mismos:

-- a) Cada vez que se agregue un registro en la tabla Tratamiento debe modificar el stock del
-- medicamento recetado, de acuerdo a la cantidad de dosis indicada (stock = stock - dosis).

create or replace function fn_alta_tratamiento() returns trigger
as
$tr_altatratamiento$
declare
    existe_medicamento boolean;
    nuevo_stock        int;
begin
    select exists(select 1 from medicamento m where m.id_medicamento = new.id_medicamento) into existe_medicamento;

    if not existe_medicamento then
        raise exception 'No existe el medicamento recetado en el tratamiento';
    end if;

    nuevo_stock := abs((select stock from medicamento m where m.id_medicamento = new.id_medicamento) - new.dosis);

    if nuevo_stock < 0 then
        update medicamento m set stock = 0 from tratamiento t where m.id_medicamento = t.id_medicamento;
    else
        update medicamento m set stock = nuevo_stock from tratamiento t where m.id_medicamento = t.id_medicamento;
    end if;

    return new;
end;

$tr_altatratamiento$
    language plpgsql;

create or replace trigger tr_alta_tratamiento
    before insert
    on tratamiento
    for each row
execute procedure fn_alta_tratamiento();

-- b) Cuando se agrega un registro a la tabla Compra debe actualizar el stock del medicamento
-- comprado de acuerdo a la cantidad adquirida (stock = stock + cantidad).

create or replace function fn_alta_compra() returns trigger
as
$tr_alta_compra$
declare
    existe_medicamento boolean;
begin
    select exists(select 1 from medicamento m where m.id_medicamento = new.id_medicamento) into existe_medicamento;

    if not existe_medicamento then
        raise exception 'No existe el medicamento seleccionado en la compra';
    end if;

    update medicamento m set stock = stock + new.cantidad where m.id_medicamento = new.id_medicamento;
end;

$tr_alta_compra$
    language plpgsql;

create or replace trigger tr_alta_compra
    before insert
    on compra
    for each row
execute procedure fn_alta_compra();

-- c) Cada vez que se realice un pago debe modificar los campos saldo y pagada de la tabla Factura.
-- El campo saldo es la diferencia entre el monto de la factura y la suma de los montos de la tabla
-- Pago de la factura correspondiente. La columna pagada será ‘S’ si el saldo es 0 (cero) y ‘N’ en
-- caso contrario.

create or replace function fn_pago_factura() returns trigger
as
$tr_pago_factura$
declare
    existe_factura boolean;
    nuevo_saldo    numeric(10, 2);
begin
    select exists(select 1 from factura f where f.id_factura = new.id_factura) into existe_factura;

    if not existe_factura then
        raise exception 'No existe la factura seleccionada en el pago';
    end if;

    nuevo_saldo := abs((select monto from factura f where f.id_factura = new.id_factura) -
                       (select sum(monto) from pago p where p.id_factura = new.id_factura));

    if nuevo_saldo <= 0 then
        update factura f set saldo = 0, pagada = 'S' where f.id_factura = new.id_factura;
    else
        update factura f set saldo = nuevo_saldo, pagada = 'N' where f.id_factura = new.id_factura;
    end if;

    return new;
end;
$tr_pago_factura$
    language plpgsql;

create or replace trigger tr_pago_factura
    before insert
    on pago
    for each row
execute procedure fn_pago_factura();

-- d) Cada vez que se borre un registro de la tabla Pago debe modificar los campos saldo y pagada de
-- la tabla Factura, el campo saldo tendrá el valor que tenía más el valor del monto del pago
-- eliminado de la factura correspondiente. La columna pagada deberá tener el valor ‘N’, debido a
-- que no está cancelada la deuda.

create or replace function fn_borrado_pago() returns trigger
as
$tr_borrado_pago$
declare
    existe_factura boolean;
begin
    select exists(select 1 from factura f where f.id_factura = new.id_factura) into existe_factura;

    if not existe_factura then
        raise exception 'No existe la factura seleccionada en el pago';
    end if;

    update factura f set saldo = saldo + new.monto, pagada = 'N' where f.id_factura = new.id_factura;
end;

$tr_borrado_pago$
    language plpgsql;

create or replace trigger tr_borrado_pago
    before delete
    on pago
    for each row
execute procedure fn_borrado_pago();

-- e) Cada vez que se modifique el stock de un medicamento, si el mismo es menor a 50 se debe
-- agregar un registro en una nueva tabla llamada medicamento_reponer. La tabla
-- medicamento_reponer debe tener los siguientes campos: id_medicamento, nombre,
-- presentación y el stock del medicamento, también debe tener el último precio que se pagó por
-- el mismo cuando se lo compró y a qué proveedor (solo el nombre). El trigger sólo debe activarse
-- cuando se modifique el campo stock por un valor menor, en caso contrario, no debe realizar
-- ninguna acción. Tenga en cuenta que puede darse el caso que el registro de dicho medicamento
-- ya exista en la tabla medicamento_reponer, en tal caso solo debe actualizar el campo stock.

create or replace function fn_modificar_stock_medicamento_menor_50() returns trigger
as
$tr_modificar_stock_medicamento_menor_50$
declare
    existe_medicamento_reponer boolean;
begin
    create table if not exists medicamento_reponer
    (
        id_medicamento int         not null,
        nombre         varchar(50),
        presentacion   varchar(50),
        stock          int,
        ultimo_precio  numeric(8, 2),
        proveedor      varchar(50) not null
    );

    select exists(select 1 from medicamento_reponer m where m.id_medicamento = new.id_medicamento)
    into existe_medicamento_reponer;

    if new.stock >= 50 then
        return old;
    end if;

    if existe_medicamento_reponer then
        update medicamento_reponer m set stock = new.stock where m.id_medicamento = new.id_medicamento;
    else
        insert into medicamento_reponer
        values (new.id_medicamento, new.nombre, new.presentacion, new.stock, new.precio, (select proveedor
                                                                                          from proveedor p
                                                                                                   inner join compra c using (id_proveedor)
                                                                                          where c.id_medicamento = new.id_medicamento
                                                                                          limit 1));
    end if;

    return new;
end;
$tr_modificar_stock_medicamento_menor_50$
    language plpgsql;

create or replace trigger tr_modificar_stock_medicamento_menor_50
    before update
    on medicamento
    for each row
    when (old.stock < new.stock)
execute procedure fn_modificar_stock_medicamento_menor_50();

-- f) Cada vez que se modifique el stock de un medicamento, solo si es por un valor mayor (cuando
-- se hace una compra), debe buscar si existe el registro en la tabla medicamento_reponer, y si el
-- nuevo valor del stock (stock + cantidad) es mayor a 50, debe eliminar el registro de dicha tabla,
-- de lo contrario, debe modificar el campo stock de la tabla medicamento_reponer, por el nuevo
-- stock de la tabla medicamento.
create or replace function fn_modificar_stock_medicamento_mayor() returns trigger
as
$tr_modificar_stock_medicamento_mayor$
declare
    existe_medicamento_reponer boolean;
    compra_medicamento         compra;
begin
    select exists(select 1 from medicamento_reponer m where m.id_medicamento = new.id_medicamento)
    into existe_medicamento_reponer;

    if existe_medicamento_reponer then
        select * from compra c where c.id_medicamento = new.id_medicamento limit 1 into compra_medicamento;

        if compra_medicamento.cantidad + new.stock > 50 then
            delete from medicamento_reponer m where id_medicamento = new.id_medicamento;
        else
            update medicamento_reponer mr
            set stock = compra_medicamento.cantidad + new.stock
            where mr.id_medicamento = new.id_medicamento;
        end if;

    end if;

    return new;
end;
$tr_modificar_stock_medicamento_mayor$
    language plpgsql;

create or replace trigger tr_modificar_stock_medicamento_mayor
    before update
    on medicamento
    for each row
    when ( new.stock >= old.stock )
execute procedure fn_modificar_stock_medicamento_mayor();

-- Ejercicio nro. 3:
-- Realice las siguientes auditorías por trigger.

-- a) Auditoría de medicamento: debe registrar cualquier cambio realizado en la tabla medicamento
-- en una nueva tabla llamada audita_medicamento cuyos camposserán: id (serial), usuario, fecha,
-- operación, estado, más todos los campos de la tabla medicamento (id_medicamento,
-- id_clasificacion, etc).
-- Si se agrega o borra un registro, de guardar el nombre de usuario, la fecha y hora actual, como
-- operación guardará una I ó D según corresponda, y en estado las palabras “alta” o “baja”.
-- Si la operación realizada es una modificación debe guardar dos registros en la tabla
-- audita_medicamento, uno con los valores antes dgg e ser modificados y otro con los valores ya
-- modificados, entonces, en el campo operación guardará U en ambos registros y para el registro
-- “viejo” en el campo estado debe guardar la palabra “antes” y para el registro “nuevo” el estado
-- debe decir “después”.

create or replace function fn_auditoria_medicamento() returns trigger
as
$tr_auditoria_medicamento$
begin
    create table if not exists audita_medicamento
    (
        id               serial        not null
            constraint "PK" primary key,
        usuario          varchar(50),
        fecha            date,
        operacion        character,
        estado           varchar(100),
        id_medicamento   integer       not null,
        id_clasificacion smallint      not null,
        id_laboratorio   smallint      not null,
        nombre           varchar(50)   not null,
        presentacion     varchar(50)   not null,
        precio           numeric(8, 2) not null,
        stock            integer
    );

    if tg_op = 'delete' then
        insert into audita_medicamento values (default, user, now(), 'D', 'Baja', new);
        return old;
    elseif tg_op = 'insert' then
        insert into audita_medicamento values (default, user, now(), 'I', 'Alta', new);
        return new;
    elseif tg_op = 'update' then
        insert into audita_medicamento values (default, user, now(), 'U', 'Nuevo', new);
        insert into audita_medicamento values (default, user, now(), 'U', 'Antes', old);
        return new;
    end if;
end;
$tr_auditoria_medicamento$ language plpgsql;

create or replace trigger tr_auditoria_medicamento
    after insert or delete or update
    on medicamento
    for each row
execute procedure fn_auditoria_medicamento();

-- b) Auditoría de empleados: debe guardar los datos en una tabla llamada audita_empleado_sueldo
-- cuyos campos serán: id (serial), usuario, fecha, id_empleado, dni, nombre y apellido del
-- empleado, también debe tener un campo sueldo_v (sueldo antes de modificar), sueldo_n
-- (sueldo después de modificar), un campo diferencia que llevará la diferencia entre el sueldo
-- anterior y el nuevo, y un campo estado, en el cual se guardará “aumento”, si el sueldo nuevo es
-- mayor al anterior o “descuento” en caso contrario.
-- Esta auditoría sólo se debe ejecutar en caso que se realice una modificación en el sueldo del
-- empleado, cualquier otra operación realizada en la tabla Empleado debe ser ignorada por esta
-- auditoría.

create or replace function fn_audita_empleado_sueldo() returns trigger
as
$tr_audita_empleado_sueldo$
declare
    datos_empleado    persona;
    diferencia_sueldo numeric(9, 2);
    estado_sueldo     varchar(25);
begin
    create table if not exists audita_empleado_sueldo
    (
        id          serial not null,
        usuario     varchar(50),
        fecha       date,
        id_empleado int    not null,
        dni         varchar(8),
        nombre      varchar(50),
        apellido    varchar(50),
        sueldo_v    numeric(9, 2),
        sueldo_n    numeric(9, 2),
        diferencia  numeric(9, 2),
        estado      VARCHAR(25)
    );

    select *
    from persona p
             inner join public.empleado e on p.id_persona = new.id_empleado
    into datos_empleado;

    if tg_op = 'update' then
        diferencia_sueldo := abs(old.sueldo - new.sueldo);
        case
            when old.sueldo > new.sueldo then estado_sueldo := 'Descuento';
            when new.sueldo >= old.sueldo then estado_sueldo := 'Aumento';
            end case;

        insert into audita_empleado_sueldo
        values (default, user, now(), datos_empleado.id_persona, datos_empleado.dni, datos_empleado.nombre,
                datos_empleado.apellido, old.sueldo, new.sueldo, diferencia_sueldo, estado_sueldo);
    end if;
end;
$tr_audita_empleado_sueldo$
    language plpgsql;

create or replace trigger tr_audita_empleado_sueldo
    before update
    on empleado
    for each row
    when (old.sueldo != new.sueldo )
execute procedure fn_audita_empleado_sueldo();

-- c) Auditoría de tablas: debe guardar los datos en una nueva tabla llamada audita_tablas_sistema
-- cada vez que se elimine una consulta, un estudio realizado o un tratamiento cuyos campos serán:
-- id (serial), usuario y fecha, el id del paciente, la fecha en la que se realizó la consulta, estudio o
-- indicación del tratamiento y el nombre de la tabla a la que corresponde el registro borrado.
-- Ante cualquier otra acción en estas tablas, esta auditoría no se debe ejecutar. También debe
-- guardar el registro borrado en una tabla llamada estudio_borrado, consulta_borrada o
-- tratamiendo_borrado, según corresponda, los campos de las nuevas tablas serán los mismos
-- que los de las tablas originales.


create or replace function fn_audita_tablas_sistema() returns trigger
as
$tr_audita_tablas_sistema$
begin
    create table if not exists audita_tablas_sistema
    (
        id                   serial       not null,
        usuario              varchar(50)  not null,
        fecha                date         not null,
        id_paciente          int          not null,
        fecha_consulta       date         not null,
        nombre_tabla_borrado varchar(100) not null
    );

    if tg_table_name = 'consulta' then
        create table if not exists consulta_borrada
        (
            id_paciente    integer  not null,
            id_empleado    integer  not null,
            fecha          date     not null,
            id_consultorio smallint not null,
            hora           time,
            resultado      varchar(100)
        );

        insert into audita_tablas_sistema values (default, user, now(), old.id_paciente, old.fecha, tg_table_name);

        insert into consulta_borrada
        values (old.id_paciente, old.id_empleado, old.fecha, old.id_consultorio, old.hora, old.resultado);

    elseif tg_table_name = 'estudio_realizado' then
        create table if not exists estudio_borrado
        (
            id_paciente integer  not null,
            id_estudio  smallint not null,
            fecha       date     not null,
            id_equipo   smallint not null,
            id_empleado integer  not null,
            resultado   varchar(50),
            observacion varchar(100),
            precio      numeric(10, 2)
        );

        insert into audita_tablas_sistema values (default, user, now(), old.id_paciente, old.fecha, tg_table_name);

        insert into estudio_borrado
        values (old.id_paciente, old.id_estudio, old.fecha, old.id_equipo, old.id_empleado, old.resultado,
                old.observacion, old.precio);

    elseif tg_table_name = 'tratamiento' then
        create table if not exists tratamiento_borrado
        (
            id_paciente      integer     not null,
            id_medicamento   integer     not null,
            fecha_indicacion date        not null,
            prescribe        integer     not null,
            nombre           varchar(50) not null,
            descripcion      varchar(100),
            dosis            integer,
            costo            numeric(10, 2)
        );

        insert into audita_tablas_sistema
        values (default, user, now(), old.id_paciente, old.fecha_indicacion, tg_table_name);

        insert into tratamiento_borrado
        values (old.id_paciente, old.id_medicamento, old.fecha_indicacion, old.preescribe, old.nombre, old.descripcion,
                old.dosis, old.costo);
    else
        raise exception 'Se llamó esta función sobre una tabla errada';
    end if;

    return old;
end;
$tr_audita_tablas_sistema$
    language plpgsql;

create or replace trigger tr_audita_tablas_sistema
    after delete
    on consulta
    for each row
execute procedure fn_audita_tablas_sistema();

create or replace trigger tr_audita_tablas_sistema
    after delete
    on estudio_realizado
    for each row
execute procedure fn_audita_tablas_sistema();

create or replace trigger tr_audita_tablas_sistema
    after delete
    on tratamiento
    for each row
execute procedure fn_audita_tablas_sistema();