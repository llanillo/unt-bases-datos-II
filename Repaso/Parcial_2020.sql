EJERCICIO N° 1: Tipos de datos e índices
El siguiente modelo relacional describe el funcionamiento de un negocio de venta de productos.

a) Indique el tipo de dato para cada uno de los campos de la tabla cliente.
    id_cliente: int
    apellido: varchar(50)
    nombre: varchar(50)
    dni: varchar(10)
    fecha_nacimiento: date
    dirección: varchar(40)
    teléfono: varchar(15)

b) Que índice/s propone para la tabla producto? ¿Por qué?
    Propongo un índice por (precio), es muy común buscar productos por precio
    Propongo un índice compuesto por (precio, nombre), otra búsqueda común suele ser por estos dos campos.

    Se suele usar el precio al momento de realizar búsquedas de productos lo cual beneficiara las consultas
    que incluyan este campo en las cláusulas WHERE, además que si la tabla de productos es grande el uso
    del índice en este campo podría reducir bastante los tiempos de respuesta.

c) ¿Es conveniente crear índices por los campos fecha_nacimiento, teléfono, dirección en la tabla cliente?
justifique la respuesta.
    Sí, es conveniente crear un índice para el campo fecha_nacimiento ya que al no haber tantas repeticiones de fechas
    se podría conseguir ciertos usuarios por su fecha de nacimiento.

    También se podría crear un índice por teléfono porque permitiría encontrar usuarios por su número de teléfono de
    manera más rápida que buscándolos por nombre.

    Un índice por dirección no podría ser de tanta ayuda porque no se suelen buscar clientes por
    su dirección, además que se crearía un índice denso porque muy raras veces se repiten las direcciones

d) ¿Es conveniente hacer índice en la tabla cliente por el campo nombre y otro por el campo apellido?
    No, debido a que muchos clientes pueden tener el mismo nombre trayendo consigo muchos resultados por lo
    que las consultas no se estarían beneficiando del índice.

    Una mejor alternativa sería hacer un índice compuesto por (apellido, nombre), en ese orden, ya que los apellidos no se suelen
    repetir tantas veces como los nombres haciendo que cada consulta sea óptima al buscar los clientes. Y en caso,
    que existan varios clientes con el mismo apellido no se compararía con la cantidad de clientes que traería
    si el índice fuera por nombre primero.


EJERCICIO N° 2: Permisos
Dado el usuario UserConsulta, realice las siguientes consultas SQL e indique en cada caso, qué permisos y
sobre que tablas debería tener el mismo, para poder llevar a cabo las tareas solicitadas:

-- a) Muestre el id, nombre y la dirección de las sucursales y cuántos empleados trabajan en cada una de ellas.
    select s.id_sucursal, s.sucursal, s.direccion, count(*) from sucursales s inner join trabajan t using (id_sucursal)
    group by count(*);

    sucursales: r
    trabajan: r

b) Muestre el nombre, apellido y DNI de los clientes que no hayan comprado en las sucursales
“Centro 5”, “Plaza 2” y “Avenida 1”. También debe mostrar la cuenta corriente y en caso de tener, la
obra social. Ordenados por apellido y nombre.
    select p.nombre, p.apellido, p.dni, c.cuenta_corriente, ob.obra_social from personas p inner join clientes c on (p.id_persona = c.id_cliente)
    inner join obras_sociales ob using (id_obra_social) where p.id_persona not in
    (select id_persona from persona p inner join clientes c on (p.id_persona = c.id_cliente) inner join ventas v using (id_cliente)
    inner join sucursales s using (id_sucursal) where s.surcusal not in ('Centro 5', 'Plaza 2', 'Avenida 1'))
    order by p.apellido, p.nombre ;

    personas: r
    clientes: r
    ventas: r
    sucursales: r
    obras_sociales: r

c) Aumente en un 10%, el precio de los productos cuya clasificación sea 'PRODUCTOS PARA BEBES','GASAS'
o 'COSMETICOS', provisto por(proveedor) 'MEDIFARMA', cuyo precio sea mayor al del producto
'DURACEF 500 MG' en la presentación 'CAJA X 8 CAPSULAS'
    update productos pr set precio = precio * 1.1 using clasificaciones cl, compras c, proveedores p where
    pr.id_clasificacion = cl.id_clasificacion and c.id_producto = pr.id_producto and c.id_proveedor = p.id_proveedor
    and cl.clasificacion in ('PRODUCTOS PARA BEBES', 'GASAS', 'COSMETICOS') and p.proveedor like '%MEDIFARMA%'
    and pr.precio > (select precio from producto where nombre like '%DURACEF 500 MG%' and presentacion like '%CAJA X 8 CAPSULAS%' limit 1);


EJERCICIO N° 3: Transacciones (No usar funciones)

a) Genere una transacción que modifique el precio y la cantidad del detalle de la venta número 187 de la
siguiente manera:

    begin;

    update detalle_ventaa dv set precio = 250.25, cantidad = 3 where dv.id_producto = (select id_producto where nombre like '%SURGAN 200 MG%' limit 1)
    and dv.id_venta = 187;

    savepoint detalle_venta_surgan;

    update detalle_ventaa dv set precio = 825.75, cantidad = 2 where dv.id_producto = (select id_producto where nombre like '%SODIO BICARBONATO 8.4%%' limit 1)
    and dv.id_venta = 187;

    savepoint detalle_venta_sodio;

    update venta set total = total + (250.25 * 3 + 825.75 * 2) where id_venta = 187;

    savepoint venta_modificada;

    commit;

* En la misma transacción debe modificar el total de la venta número 187 de acuerdo a los nuevos datos
ingresados en el detalle de la venta antes indicada.
Nota: recuerde que la modificación del precio del producto no debe realizarse en la tabla productos, solo en la
tabla detalle_ventas

b) Genere una transacción que ingrese al sistema los nuevos registros en las tablas que corresponda.

    begin;

    insert into personas values ('Lee', 'Stan', 1000356);

    savepoint persona_stan;

    insert into empleados values ((select id_persona from persona where apellido like '%Lee%' and nombre lik '%Stan%' limit 1),
                                 (select id_categoria from categoria where categoria like '%B-1%'), 'Cajero', 380000));

    savepoint empleados_stan;

    insert into trabajan values ((select id_sucursal from sucursales where sucursal like '%Centro 3%'),
                                 (select id_persona from personas where apellido like '%Lee%' and nombre like '%Stan%' limit 1),
                                 '2020-05-09', (select id_turno from turnos where turno like '%TARDE%'));

    savepoint trabajan_tarde;

    commit;