-- Ejercicio 1: Cree una nueva base de datos “tp5” y realice:
-- a) A partir del siguiente modelo E-R que resuelve parte de un determinado problema, genere el Modelo
-- Relacional e impleméntelo en postgres. Utilice arreglos para los campos multivaluados y cree tipos de datos
-- donde corresponda.

create type Cargo as enum ('Administrativo', 'Vendedor', 'Cajero', 'Gerente');

create type Sector as enum ('Ventas', 'Compras', 'Gerencia', 'Depósito');

create type Categoria as enum ('Lácteos', 'Carnes', 'Bebidas', 'Cereales');

create type Domicilio as
(
    calle     varchar(50),
    numero    smallint,
    ciudad    varchar(100),
    provincia varchar(50)
);

create table persona
(
    id_persona int not null primary key,
    nombre     varchar(50),
    dni        int,
    Domicilio  domicilio,
    email      varchar(50)[],
    telefono   varchar(14)[],
    constraint persona_dni_unique unique (dni)
);

create table empleado
(
    Cargo  cargo,
    legajo smallint,
    sueldo numeric(10, 2),
    Sector sector,
    constraint empleado_primary_key primary key (id_persona),
    constraint empleado_unique_dni unique (dni)
) inherits (persona);

create table cliente
(
    cta_cte varchar(50),
    constraint cliente_primary_key primary key (id_persona),
    constraint cliente_unique_dni unique (dni)
) inherits (persona);

create table pedido
(
    id_pedido   int not null primary key,
    fecha       date,
    total       int,
    id_empleado int,
    id_cliente  int,
    constraint pedido_fk_empleado foreign key (id_empleado) references empleado (id_persona),
    constraint pedido_fk_cliente foreign key (id_cliente) references cliente (id_persona)
);

create table Producto
(
    id_producto int not null primary key,
    nombre      varchar(50),
    descripcion varchar(50),
    precio      numeric(10, 2),
    proveedor   varchar(50)[],
    Categoria   categoria
);

create table tiene
(
    id_pedido   int,
    id_producto int,
    precio      numeric(10, 2),
    constraint tiene_fk_pedido foreign key (id_pedido) references pedido (id_pedido),
    constraint tiene_fk_producto foreign key (id_producto) references Producto (id_producto)
);

-- b) Inserte los siguientes registros en cada una de las tablas. Utilice transacciones por cada tabla.

begin;

insert into empleado
values (1, 'VILCARROMERO, ERICK', 17130935, row ('AV SANTA ROSA', 1177, 'S.M.TUC', 'TUCUMÁN'),
        '{ "vil@gmail.com", "vilco@live.com"}', '{"4319842", "4235554", "381555414"}', 'Cajero', 1232, 150000);

savepoint carga_empleado_erick;

insert into empleado
values ((select max(id_persona) + 1 from empleado), 'MUNIZ, SILVA', 27418519,
        row ('AV. AREQUIPA', 1177, 'SALTA', 'SALTA'), '{"muniz@gmail.com","
silvi@gmail.com"}', '{"4404170", "4211111", "4222222", "38154848"}', 'Gerente', 1002, 192000, 'Gerencia');

savepoint carga_empleado_silva;

insert into cliente
values ((select max(id_persona) + 1 from persona), 'JARUFE, ERNESTO', 31569934,
        row ('LAS BEGONIAS', 451, 'LA PLATA', 'BS. AS'), '{"jarus@gmail.com"}', '{"4828283", "4979797"}', 1254);

savepoint carga_cliente_jarufe;

insert into cliente
values ((select max(id_persona) + 1 from persona), 'VASQUEZ, JUAN', 44125608,
        row ('AV PASEO DE LA REPUBLICA', 3755, 'SALTA', 'SALTA'), '{"vazquez@gmail.com", "juan@gmail.com"}',
        '{"4044444", "4555555", "4666666"}', null);

savepoint carga_cliente_vazques;

insert into cliente
values ((select max(id_persona) + 1 from persona), 'RAMES, MAYRA', 12113059,
        row ('J.P FERNANDINI', 1140, 'LA PLATA', 'BS. AS'), '{"rames@gmail.com"}',
        '{"4333333", "4181818"}', 3321);

savepoint carga_cliente_rames;

insert into cliente
values ((select max(id_persona) + 1 from persona), 'ABON, ALFREDO', 29085527,
        row ('AV. BOLIVIA', 1157, 'S.M. TUC', 'TUCUMAN'), '{"abon@gmail.com", "abon@live.com"}',
        '{"4123456", "4234567", "4345678"}', null);

savepoint carga_cliente_abon;

insert into producto
values (1, 'Coca cola', 'Botella 1.5 litros', 480.00, '{"DistriTuc, coca cola s.a"}', 'Bebidas');

savepoint carga_producto_coca;

insert into producto
values ((select max(id_producto) + 1 from producto), 'Yogurisimo', 'Yogurt gusto frutilla 1lt', 575,
        '{"Lacteos s.a, la serenisima"}', 'Lácteos');

savepoint carga_producto_yoguisimo;

insert into producto
values ((select max(id_producto) + 1 from producto), 'Hamburguesas', 'Pack x4', 620, '{"Paty s.a, distirBurger"}',
        'Carnes');

savepoint carga_producto_hamburguesas;

insert into producto
values ((select max(id_producto) + 1 from producto), 'Yogurisimo cereaal', 'Yogurt gusto grutilla 159gr', 250.50,
        '{"Lacteos s.a, la serenisima"}', 'Cereales');

savepoint carga_producto_yugurisimo_cereal;

commit;

-- Ejercicio 2: En la base de datos HOSPITAL, cree los tipos de datos que cumplan con los siguientes requerimientos:
--
-- a) Id, nombre y apellido del paciente, sigla y nombre de la obra social de los pacientes.
create type informacion_persona as
(
    id          int,
    nombre      varchar(50),
    apellido    varchar(50),
    sigla       char,
    obra_social varchar(50)
);

-- b) Id, nombre, apellido, fecha de ingreso, cargo y especialidad de los empleados.
create type Especialidad as enum ('Empleado', 'Gerente', 'Cliente');

create type informacion_empleado as
(
    id            int,
    nombre        varchar(50),
    apellido      varchar(50),
    fecha_ingreso date,
    cargo         Cargo,
    especialidad  Especialidad
);

-- c) Código, nombre, stock y clasificación de los medicamentos, además, el nombre del laboratorio que los
-- produce.
create type Clasificacion as enum ('Algo');

create type informacion_medicamento as
(
    codigo        int,
    nombre        varchar(50),
    stock         int,
    clasificacion Clasificacion,
    laboratorio   varchar(50)
);

-- d) Nombre y apellido del paciente, nombre y apellido del médico, fecha de la consulta y nombre del
-- consultorio donde se realizó la misma.
create type informacion_paciente as
(
    nombre           varchar(50),
    apellido         varchar(50),
    nombre_medico    varchar(50),
    apellido_medicao varchar(50),
    fecha_consulta   date,
    consultorio      varchar(50)
);

-- e) Nombre y apellido del paciente, nombre y apellido del empleado, nombre, precio del estudio y fecha en
-- el que se realizó el mismo.
create type informacion_paciente as
(
    nombre_completo_paciente varchar(100),
    nombre_completo_empleado varchar(100),
    estudio                  varchar(50),
    precio                   numeric(10, 2),
    fecha                    date
);

-- f) Nombre y apellido del paciente, nombre y apellido del médico, costo y fecha de alta de la internación.
create type informacion_medico as
(
    nombre_completo_paciente varchar(100),
    nombre_completo_medico   varchar(100),
    costo                    numeric(10, 2),
    fecha_alta               date
);

-- g) Nombre y apellido del paciente, nombre y apellido del médico, nombre del medicamentos, dosis y costo
-- del tratamiento.
create type informacion_tratamiento as
(
    nombre_completo_paciente varchar(100),
    nombre_completo_medico   varchar(100),
    medicamento              varchar(50),
    dosis                    int,
    costo                    numeric(10, 2)
);

-- h) Id, fecha y monto de la factura, nombre y apellido del paciente a quien le emitieron la factura.
create type factura as
(
    id                       int,
    monto                    numeric(10, 2),
    nombre_completo_paciente varchar(100)
);

-- i) Nombre y apellido del paciente, fecha y monto de los pagos realizados.
create type pago_realizado as
(
    nombre_completo_paciente varchar(100),
    fecha                    date,
    monto                    numeric(10, 2)
);

-- j) Nombre y apellido del empleado, nombre y marca del equipo, fecha de ingreso y estado de los equipos
create type estado_equipo as
(
    nombre_completo_empleado varchar(100),
    equipo                   varchar(50),
    marca                    varchar(50),
    fecha_ingreso            date,
    estado                   varchar(50)
);