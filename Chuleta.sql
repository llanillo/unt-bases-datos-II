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
create index index_informacion_cama on cama (tipo, estado);

-- CREAR Y ELIMINAR GRUPOS/ROLES
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

-- DAR PERMISOS DE SELECCION, INSERCION, UPDATE DELETE
grant select, insert, update, delete on table consulta, empleado, persona, diagnostico, tratamiento to grupo_informes;

-- DAR PERMISOS DE SELECCION, INSERCION, UPDATE DELETE PARA CIERTAS COLUMNAS
grant select, insert, update, delete (campos) on table consulta, empleado, persona, diagnostico, tratamiento to grupo_informes;

-- PROCESO DE TRANSACCIÓN
begin transaction ;

select * from persona;

savepoint punto_guardado;

rollback to punto_guardado;
rollback ;
commit ;