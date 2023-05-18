-- UPDATE
update medicamento me
set precio = precio * 1.02
from laboratorio lab,
     clasificacion cla
where lab.id_laboratorio = me.id_laboratorio
  and me.id_clasificacion = cla.id_clasificacion
  and cla.clasificacion like '%ANALGESICO%'
  and lab.laboratorio like '%ABBOTT LABORATORIOS%';

-- DELETE
delete
from tratamiento
where id_medicamento = (select id_medicamento from medicamento where nombre like '%SALBUTOL GOTAS%');

-- EXTRAER DIA, MES O AÑO DE UNA FECHA
select date_part('day', now());

-- CREAR ÍNDICES
-- CREATE [ UNIQUE ] INDEX [ IF NOT EXISTS ] name ON table_name
-- [ USING method ] [ ASC | DESC ] [ NULLS { FIRST | LAST } ]
-- [ WHERE predicate ]
create index index_informacion_cama on cama (tipo, estado);
create index index_compra on compra (cantidad) where compra.cantidad > 50;

-- A continuación, se presenta una lista concisa de algunos casos en los que conviene utilizar índices en una base de datos:
--
-- Columnas que se utilizan con frecuencia en cláusulas WHERE.
-- Columnas que se utilizan con frecuencia en cláusulas JOIN.
-- Columnas que se utilizan con frecuencia para ordenar los resultados de las consultas.
-- Columnas con una alta cardinalidad (pocos valores distintos).
-- Columnas que se utilizan en consultas complejas y que tardan mucho tiempo en ejecutarse sin un índice.
-- Tablas grandes en las que las consultas tardan mucho tiempo en ejecutarse sin índices.

-- CREAR Y ELIMINAR GRUPOS/ROLES/USUARIOS

-- CREATE ROLE name [ [ WITH ] option [ ... ] ]
-- | SUPERUSER | NOSUPERUSER | CREATEDB | NOCREATEDB
-- | CREATEROLE | NOCREATEROLE | INHERIT | NOINHERIT
-- | LOGIN | NOLOGIN | CONNECTION LIMIT connlimit
-- | [ ENCRYPTED | UNENCRYPTED ] PASSWORD 'password'
-- | VALID UNTIL 'timestamp‘;

drop role grupo_informes;

create role grupo_informes with
    nosuperuser
    nocreatedb
    nocreaterole
    nocreateuser
    inherit
    login
    connection limit -1
    valid until 'infinity';

-- ALTER ROLE User_name WITH NOCREATEDB NOCREATEUSER
-- PASSWORD 'n3WP4s4’ VALID UNTIL ’2022-01-01’;

-- drop role user_name;

-- DAR PERMISOS DE SELECCION, INSERCION, UPDATE DELETE
grant select, insert, update, delete on table consulta, empleado, persona, diagnostico, tratamiento to grupo_informes;

-- DAR PERMISOS DE SELECCION, INSERCION, UPDATE DELETE PARA CIERTAS COLUMNAS
grant select (fecha, hora) on consulta, empleado, persona, diagnostico, tratamiento to grupo_informes;

revoke select on consulta from grupo_informes;

revoke all on consulta from grupo_informes;

-- PROCESO DE TRANSACCIÓN
begin transaction;

select *
from persona;

savepoint punto_guardado;

rollback to punto_guardado;
rollback;
commit;