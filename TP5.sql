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

create table Persona
(
    id_persona int not null primary key,
    nombre     varchar(50),
    dni        int,
    Domicilio  domicilio,
    email      varchar(50)[],
    telefono   varchar(14)[],
    constraint persona_dni_unique unique (dni)
);

create table Empleado
(
    Cargo  cargo,
    legajo smallint,
    sueldo numeric(10, 2),
    Sector sector,
    constraint empleado_primary_key primary key (id_persona),
    constraint empleado_unique_dni unique (dni)
) inherits (Persona);

create table Cliente
(
    cta_cte varchar(50),
    constraint cliente_primary_key primary key (id_persona),
    constraint cliente_unique_dni unique (dni)
) inherits (Persona);

create table Pedido
(
    id_pedido   int not null primary key,
    fecha       date,
    total       int,
    id_empleado int,
    id_cliente  int,
    constraint pedido_fk_empleado foreign key (id_empleado) references Empleado (id_persona),
    constraint pedido_fk_cliente foreign key (id_cliente) references Cliente (id_persona)
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

create table Tiene
(
    id_pedido   int,
    id_producto int,
    precio      numeric(10, 2),
    constraint tiene_fk_pedido foreign key (id_pedido) references Pedido (id_pedido),
    constraint tiene_fk_producto foreign key (id_producto) references Producto (id_producto)
);

-- b) Inserte los siguientes registros en cada una de las tablas. Utilice transacciones por cada tabla.

begin;

insert into Empleado
values (1, 'VILCARROMERO, ERICK', 17130935, row ('AV SANTA ROSA', 1177, 'S.M.TUC', 'TUCUMÁN'),
        '{ "vil@gmail.com", "vilco@live.com"}', '{"4319842", "4235554", "381555414"}', 1, 'Cajero', '1232');

savepoint carga_persona;

commit;
