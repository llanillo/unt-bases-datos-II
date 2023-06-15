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

create trigger tr_alta_tratamiento
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

create trigger tr_alta_compra
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

create trigger tr_pago_factura
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

create trigger tr_borrado_pago
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

create or replace function fn_modificar_medicamento() returns trigger
as
$tr_modificar_medicamento$
declare

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

end;

$tr_modificar_medicamento$
    language plpgsql;
create trigger tr_modificar_medicamento
    before update
    on medicamento
    for each row
    when (old.stock < new.stock)
execute procedure fn_modificar_medicamento();

-- f) Cada vez que se modifique el stock de un medicamento, solo si es por un valor mayor (cuando
-- se hace una compra), debe buscar si existe el registro en la tabla medicamento_reponer, y si el
-- nuevo valor del stock (stock + cantidad) es mayor a 50, debe eliminar el registro de dicha tabla,
-- de lo contrario, debe modificar el campo stock de la tabla medicamento_reponer, por el nuevo
-- stock de la tabla medicamento.

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


-- b) Auditoría de empleados: debe guardar los datos en una tabla llamada audita_empleado_sueldo
-- cuyos campos serán: id (serial), usuario, fecha, id_empleado, dni, nombre y apellido del
-- empleado, también debe tener un campo sueldo_v (sueldo antes de modificar), sueldo_n
-- (sueldo después de modificar), un campo diferencia que llevará la diferencia entre el sueldo
-- anterior y el nuevo, y un campo estado, en el cual se guardará “aumento”, si el sueldo nuevo es
-- mayor al anterior o “descuento” en caso contrario.
-- Esta auditoría sólo se debe ejecutar en caso que se realice una modificación en el sueldo del
-- empleado, cualquier otra operación realizada en la tabla Empleado debe ser ignorada por esta
-- auditoría.


-- c) Auditoría de tablas: debe guardar los datos en una nueva tabla llamada audita_tablas_sistema
-- cada vez que se elimine una consulta, un estudio realizado o un tratamiento cuyos campos serán:
-- id (serial), usuario y fecha, el id del paciente, la fecha en la que se realizó la consulta, estudio o
-- indicación del tratamiento y el nombre de la tabla a la que corresponde el registro borrado.
-- Ante cualquier otra acción en estas tablas, esta auditoría no se debe ejecutar. También debe
-- guardar el registro borrado en una tabla llamada estudio_borrado, consulta_borrada o
-- tratamiendo_borrado, según corresponda, los campos de las nuevas tablas serán los mismos
-- que los de las tablas originales.